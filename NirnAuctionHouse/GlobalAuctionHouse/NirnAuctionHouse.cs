using System;
using System.Collections.Generic;
using System.Linq;
using System.Windows.Forms;
using System.IO;
using LuaTableHandlers;
using System.Web.Script.Serialization;
using System.Diagnostics;
using System.Net;
using System.Text.RegularExpressions;


using File=System.IO.File;
using System.Media;

namespace GlobalAuctionHouse
{
    public enum GameServer
    {
        NotFound,
        NA,
        EU
    }
    


    public partial class Form1 : Form
    {
        

        private const int MessageListMaxCount = 100;

        private string StatusText;


        private DateTime LastParseTime;

        private string LastSyncTimeString;
        private DateTime LastSyncTime;

        private static System.Windows.Forms.Timer aTimer;

        private DateTime LastSyncTimeBid;
        private DateTime LastSyncTimeFOs;
        private DateTime LastSyncTimePaidOrder;




        private Dictionary<string, AuctionBidEntry> _currentBidsData;

        private string ActiveAccount = "";
        private string ActiveAccountUUID = "";


        private string LogDir = "Log";

        public string LivePathDirectory = Path.GetFullPath("../../");
        public string SavedVariableDirectory = Path.GetFullPath("../../SavedVariables");
        public const string SavedVariableFileName = "NirnAuctionHouse.lua";
        public GameServer CurGameServer;
        

           



        public string TradeListPath;
        public string BidListPath;
        public string TrackedBidListPath;
        

        public  Uri APIEndpoint;
        
        public string ApplicationName = "NirnAuctionHouse";

        public string UpdaterPath;

        public string AddonDirectory = Path.GetFullPath("../NirnAuctionHouse");

        public bool DoPlaySounds = true;
        public bool DoPlaySounds_success_listing = false;
        public bool DoPlaySounds_success_buy = false;
        public bool DoPlaySounds_success_cancel = false;

        bool DoActiveSellersOnly = false;


        bool foundAccount = false;


        public Form1()
        {
            InitializeComponent();
            this.LastSyncTime = DateTime.Now;
            this.StatusText = "Ready for Upload";
            label1.Text = this.StatusText;

            ///////////////////////only allow 1 instance at a time///////////////////////
            Process[] ps = Process.GetProcessesByName("NirnAuctionHouse");
            if (ps != null)
            {
                Process myp = Process.GetCurrentProcess();
                foreach (Process p in ps)
                {
                   
                    if (p.Id != myp.Id)
                    {
                        p.Kill();
                    }

                }
               
            }
            ////////////////kill any other instance of nirn auction house that launches/////////////////////
            
             Application.ApplicationExit += new EventHandler(this.OnApplicationExit);


            this.TradeListPath = Path.Combine(this.AddonDirectory, "Trades.lua");
            this.BidListPath = Path.Combine(this.AddonDirectory, "Bids.lua");
            this.TrackedBidListPath = Path.Combine(this.AddonDirectory, "Tracked.lua");
            
            this.GetAPIEndpoint();



            this.ModInitiate();
            this.ModNotification("");
            this.StartWatchingSavedVars();
            
      

        }


        private void GetAPIEndpoint()
        {
            GetAPIEndpoint("");
        }
        private void GetAPIEndpoint(string worldname)
        {

            if (worldname=="") {
                this.CurGameServer = this.GetGameServerFromFile();
            } else
            {

                if (worldname == "NA Megaserver")
                {
                    this.CurGameServer = GameServer.NA;
                }else
                {
                    this.CurGameServer = GameServer.EU;
                }
            }
            
            if (this.CurGameServer==GameServer.NA)
            {
               this.APIEndpoint = new Uri("https://nirnah.com");
            } else
            {
                this.APIEndpoint = new Uri("https://nirnah.com/eu");
            }

        }

  



        private void button1_Click(object sender, EventArgs e)
        {
            this.ParseNPostListings();

        }


        private void ParseNPostListings()
        {
            bool oktoSync = false;

            if (LastSyncTime == null)
            {
                oktoSync = true;
            }
            else
            {
                TimeSpan totalTimeTaken = DateTime.Now.Subtract(LastSyncTime);
                if (totalTimeTaken.TotalMilliseconds > 5000)
                {
                    
                    oktoSync = true;
                }

            }

            if (!oktoSync) { return; }
            

            if (ActiveAccount == "" || ActiveAccount == "@" || ActiveAccount == "\"\"")
            {
                this.StatusText = "Loading Active Account";
               // label1.Text = this.StatusText;
                this.LoadActiveAccount();
            }

            if (ActiveAccountUUID == null || ActiveAccountUUID == "")
            {
                this.StatusText = "Loading Active Account UUID";
                // label1.Text = this.StatusText;
                this.UpdateUUID();
            }


            if (ActiveAccount == "" || ActiveAccount == "@" || ActiveAccount == "\"\"" || ActiveAccountUUID == null || ActiveAccountUUID == "")
            {
                this.ToLog("ParseNPostListings no active account");
                return;
            }

            

            this.StatusText = "Preparing Upload";
            label1.Text = this.StatusText;
            string str = Path.Combine(SavedVariableDirectory, "NirnAuctionHouse.lua");
            if (!File.Exists(str))
            {
                //this.ToLog("Auction House Saved File doesnt exist yet: " + str);
                this.StatusText = "Auction House Saved File doesnt exist yet";
                label1.Text = this.StatusText;
                return;
            }



            this.StatusText = "Starting Trade Upload";
            label1.Text = this.StatusText;


           
                try
                {
                    string str1 = System.IO.File.ReadAllText(str);

                    this.StatusText = "Fetching Trades";
                    label1.Text = this.StatusText;

                    if (!string.IsNullOrEmpty(str1))
                    {

                        this.StatusText = "Loading Trades";
                        label1.Text = this.StatusText;

                        Dictionary<string, LsonValue> SavedVariableFileData = ReadSavedVariableFile();
                        if (SavedVariableFileData != null)
                        {

                            this.StatusText = "Loaded Trades";
                            label1.Text = this.StatusText;
                            if (SavedVariableFileData.ContainsKey("NirnAuctionHouseData"))
                            {
                                LsonValue item = SavedVariableFileData["NirnAuctionHouseData"]["Default"];
                            
                                    

                                    AuctionTradeData FirstAuctionTradeData = AuctionTradeData.LoadFromSavedVars(item[ActiveAccount], ActiveAccount + "~" + ActiveAccountUUID);


                                if (FirstAuctionTradeData.AuctionEntries == null)
                                {
                                    this.StatusText = "No Trades Found for " + FirstAuctionTradeData.Name;
                                        label1.Text = this.StatusText;
                                    return;
                                }

                                this.StatusText = "Loaded Trades for " + FirstAuctionTradeData.Name;
                                label1.Text = this.StatusText;

                                    AuctionEntry firstTradeAsset = FirstAuctionTradeData.AuctionEntries.FirstOrDefault<AuctionEntry>();

                                if (firstTradeAsset != null)
                                {
                                    string firstTradeAssetName = firstTradeAsset.ItemData.Item.Name;

                                    if (firstTradeAssetName != "")
                                    {
                                        this.StatusText = "Loaded First Trade Asset for " + FirstAuctionTradeData.Name + " [ " + firstTradeAssetName + " ]";
                                        label1.Text = this.StatusText;

                                    }
                                    else
                                    {
                                        this.StatusText = "No Trade Asset found for " + FirstAuctionTradeData.Name;
                                        label1.Text = this.StatusText;
                                    }

                                }
                                else
                                {
                                    this.StatusText = "No Trade Asset found for " + FirstAuctionTradeData.Name;
                                    label1.Text = this.StatusText;
                                }
                                
                                    this.PostTrades(FirstAuctionTradeData.AuctionEntries);

                            


                            this.LastSyncTimeString = DateTime.Now.ToShortTimeString();
                            this.LastSyncTime = DateTime.Now;
                            this.UpdateTradeList();
                        }

                            //Settings.Default.Save();
                            return;
                            //}
                        }
                    }
                }
                finally
                {
                    //done
                }
            

        }





        private void ParseNPostFilledOrders()
        {

            bool oktoSync = false;

            if (LastSyncTimeFOs == null)
            {
                oktoSync = true;
            }
            else
            {
                TimeSpan totalTimeTaken = DateTime.Now.Subtract(LastSyncTimeFOs);
                if (totalTimeTaken.TotalMilliseconds > 5000)
                {
                  //  this.StatusText = "bid totalTimeTaken.TotalMilliseconds: " + totalTimeTaken.TotalMilliseconds;
                 //   label1.Text = this.StatusText;
                    oktoSync = true;
                }

            }

            if (!oktoSync) { return; }


            if (ActiveAccount == "" || ActiveAccount == "@" || ActiveAccount == "\"\"")
            {
                this.StatusText = "Loading Active Account";
               // label1.Text = this.StatusText;
                this.LoadActiveAccount();
            }

            if (ActiveAccountUUID == null || ActiveAccountUUID == "")
            {
                this.StatusText = "Loading Active Account UUID";
                // label1.Text = this.StatusText;
                this.UpdateUUID();
            }



            if (ActiveAccount == "" || ActiveAccount == "@" || ActiveAccount == "\"\"" || ActiveAccountUUID == null || ActiveAccountUUID == "") { return; }

            //for debugging
            //this.LastSyncTime = DateTime.Now;
            //return;

            this.StatusText = "Preparing Upload";
            label1.Text = this.StatusText;
            string str = Path.Combine(SavedVariableDirectory, "NirnAuctionHouse.lua");
            if (!File.Exists(str))
            {
               // this.ToLog("Auction House Saved File doesnt exist yet: " + str);
                this.StatusText = "Auction House Trade File doesnt exist yet";
                label1.Text = this.StatusText;
                return;
            }



            this.StatusText = "Starting Filled Order Upload";
            label1.Text = this.StatusText;

            
                try
                {
                  

                  
                        this.StatusText = "Loading Filled Orders";
                        label1.Text = this.StatusText;

                    Dictionary<string, LsonValue> SavedVariableFileData = ReadSavedVariableFile();
                        if (SavedVariableFileData != null)
                        {

                            this.StatusText = "Loaded Filled Orders";
                            label1.Text = this.StatusText;

                            if (SavedVariableFileData.ContainsKey("NirnAuctionHouseData"))
                            {
                            LsonValue item = SavedVariableFileData["NirnAuctionHouseData"]["Default"];
                           
                                LsonValue activeaccountLUAOBJ = item[ActiveAccount];

                                List<AuctionFilledOrderEntry> TmpFilledOrders = new List<AuctionFilledOrderEntry>();
                                LsonValue items = activeaccountLUAOBJ;
                                LsonValue Bitem = items["$AccountWide"]["data"]["FilledOrders"];
                                    foreach (string key in Bitem.Keys)
                                    {
                                        AuctionFilledOrderEntry TmpFilledOrder = new AuctionFilledOrderEntry(Bitem[key], ActiveAccount + "~" + ActiveAccountUUID);
                                        if (TmpFilledOrder.TradeID > 0)
                                        {
                                        TmpFilledOrders.Add(TmpFilledOrder);
                                        }
                                    }





                                    AuctionFilledOrderEntry TmpFilledOrderFirst = TmpFilledOrders.FirstOrDefault<AuctionFilledOrderEntry>((AuctionFilledOrderEntry x) => x.TradeID > 0);


                                if (TmpFilledOrderFirst == null)
                                {
                                    this.StatusText = "No Filled Orders Found for " + ActiveAccount;
                                    label1.Text = this.StatusText;
                                    return;
                                }

                                this.StatusText = "Loaded Filled Orders for " + ActiveAccount;
                                label1.Text = this.StatusText;


                                if (TmpFilledOrderFirst != null)
                                {

                                    if (TmpFilledOrderFirst.TradeID > 0)
                                    {
                                        this.StatusText = "Loaded First Filled Order for " + ActiveAccount + " [ " + TmpFilledOrderFirst.TradeID + " ]";
                                        label1.Text = this.StatusText;

                                    }
                                    else
                                    {
                                        this.StatusText = "No Filled Orders found for " + ActiveAccount;
                                        label1.Text = this.StatusText;
                                    }

                                }
                                else
                                {
                                    this.StatusText = "No Filled Orders found for " + ActiveAccount;
                                    label1.Text = this.StatusText;
                                }


                                this.PostFilledOrders(TmpFilledOrders);

                            


                            this.LastSyncTimeFOs = DateTime.Now;
                            this.UpdateBidList();
                            this.UpdateTradeList();

                        }
                            return;
                        }
                    
                }
                finally
                {
                    //done
                }
            



        }








        private void ParseNPostPaidOrders()
        {


            bool oktoSync = false;

            if (LastSyncTimePaidOrder == null)
            {
                oktoSync = true;
            }
            else
            {
                TimeSpan totalTimeTaken = DateTime.Now.Subtract(LastSyncTimePaidOrder);
                if (totalTimeTaken.TotalMilliseconds > 5000)
                {
                    oktoSync = true;
                }

            }

            if (!oktoSync) { return; }




            if (ActiveAccount == "" || ActiveAccount == "@" || ActiveAccount == "\"\"")
            {
                this.StatusText = "Loading Active Account";
                // label1.Text = this.StatusText;
                this.LoadActiveAccount();
            }

            if (ActiveAccountUUID == null || ActiveAccountUUID == "")
            {
                this.StatusText = "Loading Active Account UUID";
                // label1.Text = this.StatusText;
                this.UpdateUUID();
            }



            if (ActiveAccount == "" || ActiveAccount == "@" || ActiveAccount == "\"\"" || ActiveAccountUUID == null || ActiveAccountUUID == "") { return; }

            //for debugging
            //this.LastSyncTime = DateTime.Now;
            //return;

            this.StatusText = "Preparing Upload";
            label1.Text = this.StatusText;
            string str = Path.Combine(SavedVariableDirectory, "NirnAuctionHouse.lua");
            if (!File.Exists(str))
            {
                //this.ToLog("Auction House Saved File doesnt exist yet: " + str);
                this.StatusText = "Auction House Trade File doesnt exist yet";
                label1.Text = this.StatusText;
                return;
            }



            this.StatusText = "Starting PaidOrder Upload";
            label1.Text = this.StatusText;


            try
            {
                this.StatusText = "Loading PaidOrders";
                label1.Text = this.StatusText;

                Dictionary<string, LsonValue> SavedVariableFileData = ReadSavedVariableFile();
                if (SavedVariableFileData != null)
                {

                    this.StatusText = "Loaded PaidOrders";
                    label1.Text = this.StatusText;

                    if (SavedVariableFileData.ContainsKey("NirnAuctionHouseData"))
                    {
                        LsonValue item = SavedVariableFileData["NirnAuctionHouseData"]["Default"];

                        LsonValue activeaccountLUAOBJ = item[ActiveAccount];

                        List<AuctionPaidOrdersEntry> tmpAuctionPaidOrderEntries = new List<AuctionPaidOrdersEntry>();
                        LsonValue items = activeaccountLUAOBJ;
                        LsonValue POitem = items["$AccountWide"]["data"]["PaidOrders"];
                        foreach (string key in POitem.Keys)
                        {
                            AuctionPaidOrdersEntry tmpAuctionPaidOrderEntry = new AuctionPaidOrdersEntry(POitem[key], ActiveAccount + "~" + ActiveAccountUUID);
                            if (tmpAuctionPaidOrderEntry.ItemID != null && tmpAuctionPaidOrderEntry.ItemID>0)
                            {
                                tmpAuctionPaidOrderEntries.Add(tmpAuctionPaidOrderEntry);
                            }
                        }






                        AuctionPaidOrdersEntry FirstAuctionPaidOrderEntry = tmpAuctionPaidOrderEntries.FirstOrDefault<AuctionPaidOrdersEntry>((AuctionPaidOrdersEntry x) => x.Buyer == ActiveAccount + "~" + ActiveAccountUUID);


                        if (FirstAuctionPaidOrderEntry == null)
                        {
                            this.StatusText = "No PaidOrders Found for " + ActiveAccount;
                            label1.Text = this.StatusText;
                            return;
                        }

                        this.StatusText = "Loaded PaidOrders for " + ActiveAccount;
                        label1.Text = this.StatusText;


                        if (FirstAuctionPaidOrderEntry != null)
                        {

                            if (FirstAuctionPaidOrderEntry.ItemID > 0)
                            {
                                this.StatusText = "Loaded First PaidOrder for " + ActiveAccount + " [ " + FirstAuctionPaidOrderEntry.ItemID + " ]";
                                label1.Text = this.StatusText;

                            }
                            else
                            {
                                this.StatusText = "No PaidOrder found for " + ActiveAccount;
                                label1.Text = this.StatusText;
                            }

                        }
                        else
                        {
                            this.StatusText = "No PaidOrder found for " + ActiveAccount;
                            label1.Text = this.StatusText;
                        }


                        this.PostPaidOrders(tmpAuctionPaidOrderEntries);






                        this.LastSyncTimePaidOrder = DateTime.Now;
                    }
                    return;
                }

            }
            finally
            {
                //done
            }


        }








        private void ParseNPostBids()
        {
            bool oktoSync = false;

            if (LastSyncTimeBid == null)
            {
                oktoSync = true;
            }
            else
            {
                TimeSpan totalTimeTaken = DateTime.Now.Subtract(LastSyncTimeBid);
                if (totalTimeTaken.TotalMilliseconds > 5000)
                {
                    oktoSync = true;
                }

            }

            if (!oktoSync) { return; }




            if (ActiveAccount == "" || ActiveAccount == "@" || ActiveAccount == "\"\"")
            {
                this.StatusText = "Loading Active Account";
               // label1.Text = this.StatusText;
                this.LoadActiveAccount();
            }


            if (ActiveAccountUUID == null || ActiveAccountUUID == "")
            {
                this.StatusText = "Loading Active Account UUID";
                // label1.Text = this.StatusText;
                this.UpdateUUID();
            }

            if (ActiveAccount == "" || ActiveAccount == "@" || ActiveAccount == "\"\"" || ActiveAccountUUID == null || ActiveAccountUUID == "") { return; }

            //for debugging
            //this.LastSyncTime = DateTime.Now;
            //return;

            this.StatusText = "Preparing Upload";
            label1.Text = this.StatusText;
            string str = Path.Combine(SavedVariableDirectory, "NirnAuctionHouse.lua");
            if (!File.Exists(str))
            {
               // this.ToLog("Auction House Saved File doesnt exist yet: " + str);
                this.StatusText = "Auction House Trade File doesnt exist yet";
                label1.Text = this.StatusText;
                return;
            }



            this.StatusText = "Starting Bid Upload";
            label1.Text = this.StatusText;


                try
                {                    
                        this.StatusText = "Loading Bids";
                        label1.Text = this.StatusText;

                    Dictionary<string, LsonValue> SavedVariableFileData = ReadSavedVariableFile();
                    if (SavedVariableFileData != null)
                        {

                            this.StatusText = "Loaded Bids";
                            label1.Text = this.StatusText;

                            if (SavedVariableFileData.ContainsKey("NirnAuctionHouseData"))
                            {
                            LsonValue item = SavedVariableFileData["NirnAuctionHouseData"]["Default"];

                            LsonValue activeaccountLUAOBJ = item[ActiveAccount];
                                    
                                List<AuctionBidEntry> tmpAuctionBidEntries = new List<AuctionBidEntry>();
                            LsonValue items = activeaccountLUAOBJ;
                            LsonValue Bitem = items["$AccountWide"]["data"]["Bids"];
                                    foreach (string key in Bitem.Keys)
                                    {
                                        AuctionBidEntry tmpAuctionBidEntry = new AuctionBidEntry(Bitem[key], ActiveAccount + "~" + ActiveAccountUUID);
                                        if (tmpAuctionBidEntry.ItemLink != "")
                                        {
                                    tmpAuctionBidEntries.Add(tmpAuctionBidEntry);
                                        }
                                    }






                                    AuctionBidEntry FirstAuctionBidEntry = tmpAuctionBidEntries.FirstOrDefault<AuctionBidEntry>((AuctionBidEntry x) => x.Buyer == ActiveAccount + "~" + ActiveAccountUUID);


                                if (FirstAuctionBidEntry == null)
                                {
                                    this.StatusText = "No Bids Found for " + ActiveAccount;
                                    label1.Text = this.StatusText;
                                    return;
                                }

                                this.StatusText = "Loaded Bids for " + ActiveAccount;
                                label1.Text = this.StatusText;


                                if (FirstAuctionBidEntry != null)
                                {

                                    if (FirstAuctionBidEntry.ItemID > 0)
                                    {
                                        this.StatusText = "Loaded First Bid for " + ActiveAccount + " [ " + FirstAuctionBidEntry.ItemID + " ]";
                                        label1.Text = this.StatusText;

                                    }
                                    else
                                    {
                                        this.StatusText = "No Bid found for " + ActiveAccount;
                                        label1.Text = this.StatusText;
                                    }

                                }
                                else
                                {
                                    this.StatusText = "No Bid found for " + ActiveAccount;
                                    label1.Text = this.StatusText;
                                }


                                this.PostBids(tmpAuctionBidEntries);


                            



                            this.LastSyncTimeBid = DateTime.Now;
                            this.UpdateBidList();
                        }
                            return;
                        }
                    
                }
                finally
                {
                   //done
                }
            

        }

  






        private void PostTrades(IEnumerable<AuctionEntry> tradeModels)
        {
            if (tradeModels.Count<AuctionEntry>() == 0)
            {
                
                return;
            }
            this.StatusText = "MsgPostingTrade";
            label1.Text = this.StatusText;
            try
            {
                
                string ServerResponse = this.SendPackage(this.APIEndpoint + "/proc/trade/new", tradeModels.ToList<AuctionEntry>());
                if (ServerResponse == "The resource is created successfully!" || ServerResponse == "Done!")
                {
                    ModNotification("SI_NAH_STRING_SUCCESS_LISTING");
                    this.StatusText = "Successfully Listed Item(s) for sale";
                    if (DoPlaySounds_success_listing)
                    {
                        PlaySuccessSound();
                    }
                }
                else
                {
                    //failed sound is already played by sendpackage function should the request fail

                    if (ServerResponse=="Trade Limit Reached")
                    {
                        ModNotification("SI_NAH_STRING_FAILED_LISTING_TRADELIMIT");
                        this.StatusText = "Failed to List Item(s) for sale: " + ServerResponse;
                    }
                    else
                    {
                        ModNotification("SI_NAH_STRING_FAILED_LISTING");
                        this.StatusText = "Failed to List Item(s) for sale: " + ServerResponse;

                    }
                    
                }

                label1.Text = this.StatusText;

                return;

            }
            catch (Exception exception)
            {
                this.ToLog("PostTrades Error");
                this.ToLog(exception);
            }
            this.StatusText = "Ready";
            label1.Text = this.StatusText;
        }




        

        private void PostFilledOrders(IEnumerable<AuctionFilledOrderEntry> tradeModels)
        {
            if (tradeModels.Count<AuctionFilledOrderEntry>() == 0)
            {
                return;
            }
            this.StatusText = "MsgPostingBid";
            label1.Text = this.StatusText;
          
            try
            {
                AuctionFilledOrderEntry firstFilledOrder = tradeModels.FirstOrDefault<AuctionFilledOrderEntry>();
                if (firstFilledOrder == null) { return; }
               
                string ServerResponse = this.SendPackage(this.APIEndpoint + "/proc/trade/filled", tradeModels.ToList<AuctionFilledOrderEntry>());
                if (ServerResponse == "The resource is created successfully!" || ServerResponse == "Done!")
                {
                    if (firstFilledOrder.BidID == 1)
                    {
                        ModNotification("SI_NAH_STRING_SUCCESS_CANCELED");
                        this.StatusText = "Successfully Canceled Item(s) for sale";
                        if (DoPlaySounds_success_cancel)
                        {
                            PlaySuccessSound();
                        }
                        

                    } else
                    {
                        ModNotification("SI_NAH_STRING_SUCCESS_FILLED");
                        this.StatusText = "Successfully Filled Order";
                    }
                }
                else
                {
                    //failed sound is already played by sendpackage function should the request fail
                    if (firstFilledOrder.BidID == 1)
                    {
                        ModNotification("SI_NAH_STRING_FAILED_CANCELED");
                        this.StatusText = "Failed to Cancel Item(s) for sale: " + ServerResponse;

                    }
                    else
                    {
                        ModNotification("SI_NAH_STRING_FAILED_FILLED");
                        this.StatusText = "Failed to list filled order: " + ServerResponse;
                    }
                }

                label1.Text = this.StatusText;
                return;

            }
            catch (Exception exception)
            {
                this.ToLog("PostFilledOrders Error");
                this.ToLog(exception);
            }
            this.StatusText = "Ready";
            label1.Text = this.StatusText;
        }



        private void PostBids(IEnumerable<AuctionBidEntry> tradeModels)
        {
            if (tradeModels.Count<AuctionBidEntry>() == 0)
            {
                return;
            }
            this.StatusText = "MsgPostingBid";
            label1.Text = this.StatusText;
            try
            {
                
                string ServerResponse = this.SendPackage(this.APIEndpoint + "/proc/bid/new", tradeModels.ToList<AuctionBidEntry>());
                if (ServerResponse == "The resource is created successfully!" || ServerResponse == "Done!")
                {
                    ModNotification("SI_NAH_STRING_SUCCESS_BID");
                    this.StatusText = "Successfully bid on or bought Item(s)"; 
                    if (DoPlaySounds_success_buy)
                    {
                        PlaySuccessSound();
                    }
                }
                else
                {
                    //failed sound is already played by sendpackage function should the request fail
                    ModNotification("SI_NAH_STRING_FAILED_BID");
                    this.StatusText = "Failed to bid on or buy Item(s): " + ServerResponse;
                }

                label1.Text = this.StatusText;
                return;
                
            }
            catch (Exception exception)
            {
                this.ToLog("PostBids Error");
                this.ToLog(exception);
            }
            this.StatusText = "Ready";
            label1.Text = this.StatusText;
        }




        private void PostPaidOrders(IEnumerable<AuctionPaidOrdersEntry> tradeModels)
        {
            if (tradeModels.Count<AuctionPaidOrdersEntry>() == 0)
            {
                return;
            }
            this.StatusText = "MsgPostingPaidOrder";
            label1.Text = this.StatusText;
            try
            {

                string ServerResponse = this.SendPackage(this.APIEndpoint + "/proc/trade/paid", tradeModels.ToList<AuctionPaidOrdersEntry>());
                if (ServerResponse == "The resource is created successfully!" || ServerResponse == "Done!")
                {
                    ModNotification("SI_NAH_STRING_SUCCESS_PAID");
                    this.StatusText = "Successfully Purchased Item(s) for sale";
                }
                else
                {
                    //failed sound is already played by sendpackage function should the request fail
                    ModNotification("SI_NAH_STRING_FAILED_PAID");
                    this.StatusText = "Failed to register purchased for item(s): " + ServerResponse;
                }

                label1.Text = this.StatusText;
                return;

            }
            catch (Exception exception)
            {
                this.ToLog("PostPaidOrders Error");
                this.ToLog(exception);
            }
            this.StatusText = "Ready";
            label1.Text = this.StatusText;
        }

        



        private void Form1_Load(object sender, EventArgs e)
        {

        }


        private void UpdateTradeList()
        {
            try
            {
              using (WebClient client = new WebClient()) {

                    string TradeListContent;
                    if (DoActiveSellersOnly)
                    {

                        TradeListContent = client.DownloadString(this.APIEndpoint + "/proc/tradelist/active");
                    }
                    else
                    {

                        TradeListContent = client.DownloadString(this.APIEndpoint + "/proc/tradelist");
                    }


                    string Verifycontent = TradeListContent.Replace("function NirnAuctionHouse:LoadTrades()", "");
                    Verifycontent = Verifycontent.Replace("]={[\"ID\"]=\"", "");
                    Verifycontent = Verifycontent.Replace(",[\"TimeLeft\"]=\"", "");
                    Verifycontent = Verifycontent.Replace(",[\"CharName\"]=\"@", "");
                    Verifycontent = Verifycontent.Replace(",[\"Item\"]={[\"ID\"]=", "");
                    Verifycontent = Verifycontent.Replace(",[\"Name\"]=\"", "");
                    Verifycontent = Verifycontent.Replace(",[\"StartingPrice\"]=", "");
                    Verifycontent = Verifycontent.Replace(",[\"BuyoutPrice\"]=", "");
                    Verifycontent = Verifycontent.Replace(",[\"stackCount\"]=", "");
                    Verifycontent = Verifycontent.Replace(",[\"ItemLink\"]=\"", "");
                    Verifycontent = Verifycontent.Replace("self.GlobalTrades={[", "");
                    
                     if (!Verifycontent.Contains("function") && !Verifycontent.Contains("(") && !Verifycontent.Contains(")") && !Verifycontent.Contains("--") && !Verifycontent.Contains("="))
                    {
                        File.WriteAllText(this.TradeListPath, TradeListContent);
                    }
                    else
                    {
                        this.ToLog("Unknown content recieved for Trade list");
                    }

                    
            }

            }
            catch (Exception exception)
            {
                this.ToLog(exception);
            }

        }


        

             private void UpdateUUID()
        {

            this.StatusText = "Updating UUID";
            // label1.Text = this.StatusText;

            if (ActiveAccount == "" || ActiveAccount == "@" || ActiveAccount == "\"\"")
            {
                this.StatusText = "Loading Active Account";
                // label1.Text = this.StatusText;
                this.LoadActiveAccount();
            }



            if (ActiveAccount != "" && ActiveAccount != "@" && ActiveAccount != "\"\"")
            {
                try
                {
                    string AccountUUIDFile = Path.Combine(SavedVariableDirectory, ActiveAccount + "_AccountUUID.txt");
                    Regex rgx = new Regex("[^a-zA-Z0-9 -]");
                    string UUIDContent = "";


                    if (!File.Exists(AccountUUIDFile))
                    {

                        using (WebClient client = new WebClient())
                        {

                            UUIDContent = client.DownloadString(this.APIEndpoint + "/proc/uuid/" + ActiveAccount);
                            UUIDContent = rgx.Replace(UUIDContent, "");
                            if (!UUIDContent.Contains("Attempt Detected"))
                            {
                                File.WriteAllText(AccountUUIDFile, UUIDContent);
                                ActiveAccountUUID = UUIDContent;
                            }
                            else
                            {
                                this.ToLog("Your Account is inaccessible, Please Contact the Admin Author");
                            }


                            this.StatusText = "Updated UUID";
                            //  label1.Text = this.StatusText;
                        }
                    }else
                    {
                        UUIDContent=File.ReadAllText(AccountUUIDFile);
                        UUIDContent = rgx.Replace(UUIDContent, "");
                        ActiveAccountUUID = UUIDContent;

                    }

                }
                catch (Exception exception)
                {
                    this.ToLog(exception);
                }

            }
            else
            {

                // this.ToLog("UpdateBidList no account found");

            }
        }



        private void UpdateBidList()
        {

            this.StatusText = "Updating Bid List";
           // label1.Text = this.StatusText;

            if (ActiveAccount == "" || ActiveAccount == "@" || ActiveAccount == "\"\"")
            {
                this.StatusText = "Loading Active Account";
               // label1.Text = this.StatusText;
                this.LoadActiveAccount();
            }


                if (ActiveAccountUUID==null || ActiveAccountUUID == "")
                {
                    this.StatusText = "Loading Active Account UUID";
                    // label1.Text = this.StatusText;
                    this.UpdateUUID();
                }

            if (ActiveAccount != "" && ActiveAccount != "@" && ActiveAccount != "\"\"" && ActiveAccountUUID != null &&ActiveAccountUUID != "")
            {



                try
                {

                    using (WebClient client = new WebClient())
                    {
                        
                        string BidListContent = client.DownloadString(this.APIEndpoint + "/proc/bidlist/" + ActiveAccount+ "~" + ActiveAccountUUID);
                        string Verifycontent = BidListContent.Replace("function NirnAuctionHouse:LoadBids()", "");
                        Verifycontent = Verifycontent.Replace("]={[\"ID\"]=\"", "");
                        Verifycontent = Verifycontent.Replace(",[\"TradeID\"]=\"", "");
                        Verifycontent = Verifycontent.Replace(",[\"TimeLeft\"]=\"", "");
                        Verifycontent = Verifycontent.Replace(",[\"TradeIsBidder\"]=\"", "");
                        Verifycontent = Verifycontent.Replace(",[\"Seller\"]=\"@", "");
                        Verifycontent = Verifycontent.Replace(",[\"Buyer\"]=\"@", "");
                        Verifycontent = Verifycontent.Replace(",[\"Item\"]={[\"ID\"]=", "");
                        Verifycontent = Verifycontent.Replace(",[\"BuyoutPrice\"]=", "");
                        Verifycontent = Verifycontent.Replace(",[\"stackCount\"]=", "");
                        Verifycontent = Verifycontent.Replace(",[\"ItemLink\"]=\"", "");
                        Verifycontent = Verifycontent.Replace("NirnAuctionHouse.NewBids={", "");
                        if (!Verifycontent.Contains("function") && !Verifycontent.Contains("(") && !Verifycontent.Contains(")") && !Verifycontent.Contains("--") && !Verifycontent.Contains("="))
                        {
                            File.WriteAllText(this.BidListPath, BidListContent);
                        }else
                        {
                            this.ToLog("Unknown content recieved for Bidlist");
                        }
                        
                        
                        this.StatusText = "Updated Bid List";
                      //  label1.Text = this.StatusText;
                    }

                }
                catch (Exception exception)
                {
                    this.ToLog(exception);
                }

            }
            else
            {

               // this.ToLog("UpdateBidList no account found");

            }
        }


        private void UpdateTrackedBidList()
        {

            this.StatusText = "Updating Tracked Bid List";
           // label1.Text = this.StatusText;

            if (ActiveAccount == "" || ActiveAccount == "\"\"")
            {
                this.StatusText = "Loading Active Account";
               // label1.Text = this.StatusText;
                this.LoadActiveAccount();
            }

            if (ActiveAccountUUID == null || ActiveAccountUUID == "")
            {
                this.StatusText = "Loading Active Account UUID";
                // label1.Text = this.StatusText;
                this.UpdateUUID();
            }


            if (ActiveAccount != "" && ActiveAccount != "\"\"" && ActiveAccountUUID != null && ActiveAccountUUID != "")
            {
                try
                {

                    using (WebClient client = new WebClient())
                    {
                        
                        string TrackedBidListContent = client.DownloadString(this.APIEndpoint + "/proc/mybidlist/" + ActiveAccount + "~" + ActiveAccountUUID);
                        string Verifycontent = TrackedBidListContent.Replace("function NirnAuctionHouse:LoadTrackedBids()", "");
                        Verifycontent = Verifycontent.Replace("]={[\"ID\"]=\"", "");
                        Verifycontent = Verifycontent.Replace(",[\"TradeID\"]=\"", "");
                        Verifycontent = Verifycontent.Replace(",[\"TimeLeft\"]=\"", "");
                        Verifycontent = Verifycontent.Replace(",[\"TradeIsHighestBid\"]=\"", "");
                        Verifycontent = Verifycontent.Replace(",[\"TradeIsBidder\"]=\"", "");
                        Verifycontent = Verifycontent.Replace(",[\"Seller\"]=\"@", "");
                        Verifycontent = Verifycontent.Replace(",[\"Buyer\"]=\"@", "");
                        Verifycontent = Verifycontent.Replace(",[\"Item\"]={[\"ID\"]=", "");
                        Verifycontent = Verifycontent.Replace(",[\"StartingPrice\"]=", "");
                        Verifycontent = Verifycontent.Replace(",[\"BuyoutPrice\"]=", "");
                        Verifycontent = Verifycontent.Replace(",[\"stackCount\"]=", "");
                        Verifycontent = Verifycontent.Replace(",[\"ItemLink\"]=\"", "");
                        Verifycontent = Verifycontent.Replace("NirnAuctionHouse.TrackedBids={", "");
                        if (!Verifycontent.Contains("function") && !Verifycontent.Contains("(") && !Verifycontent.Contains(")") && !Verifycontent.Contains("--") && !Verifycontent.Contains("="))
                        {
                            File.WriteAllText(this.TrackedBidListPath, TrackedBidListContent);
                        }
                        else
                        {
                            this.ToLog("Unknown content recieved for Tracked Orders");
                        }

                        this.StatusText = "Updated Tracked Bid List";
                       // label1.Text = this.StatusText;
                    }

                }
                catch (Exception exception)
                {
                    this.ToLog(this.APIEndpoint + "/proc/mybidlist/" + ActiveAccount + "~" + ActiveAccountUUID);
                    this.ToLog(exception);
                }

            }
            else
            {

               // this.StatusText = "No Account Found";
               // label1.Text = this.StatusText;

            }
        }



        // Define the event handlers.
        private void OnChangedSavedVars(object source, FileSystemEventArgs e)
        {


            this.StatusText = "OnChangedSavedVars";
            label1.Text = this.StatusText;
                this.parseSavedVars();
        }

        public void StartWatchingSavedVars()
        {
            
            this.UpdateTradeList();
            this.UpdateBidList();
            this.UpdateTrackedBidList();
            this.CheckNewBids();
            StartTimedEvents();

          


            FileSystemWatcher _watcher = new FileSystemWatcher();
            _watcher.Path = SavedVariableDirectory;
           _watcher.NotifyFilter = NotifyFilters.LastWrite;
            _watcher.Filter = "NirnAuctionHouse.lua";
            // Add event handlers.
            _watcher.Changed += new FileSystemEventHandler(this.OnChangedSavedVars);
            _watcher.Created += new FileSystemEventHandler(this.OnChangedSavedVars);
            // Begin watching.
            _watcher.EnableRaisingEvents = true;



            //FileSystemWatcher _watcher2 = new FileSystemWatcher();
            //_watcher2.Path = LivePathDirectory;
            //_watcher.NotifyFilter = NotifyFilters.LastWrite;
            //_watcher2.Filter = "UserSettings.txt";
            //// Add event handlers.
            //_watcher2.Changed += new FileSystemEventHandler(this.OnChangedSavedVars);
            //_watcher2.Created += new FileSystemEventHandler(this.OnChangedSavedVars);
            //// Begin watching.
            //_watcher2.EnableRaisingEvents = true;

            this.StatusText = "Start Watching Saved Vars";
            label1.Text = this.StatusText;
        }

        public void parseSavedVars()
        {
            bool oktoSync = false;

            if (LastParseTime == null)
            {
                oktoSync = true;
            }
            else
            {
                TimeSpan totalTimeTaken = DateTime.Now.Subtract(LastParseTime);
                if (totalTimeTaken.TotalMilliseconds > 5000)
                {

                    oktoSync = true;
                }

            }

            if (!oktoSync) { return; }
            
           foundAccount = false;
            this.ModNotification("");
            this.StatusText = "parsing saved vars";
            label1.Text = this.StatusText;

            string str = Path.Combine(SavedVariableDirectory, "NirnAuctionHouse.lua");
            if (!File.Exists(str))
            {
                //this.ToLog("Auction House Saved File doesnt exist yet: " + str);
                this.StatusText = "Auction House Saved File doesnt exist yet";
                label1.Text = this.StatusText;
                return;
            }
            Dictionary<string, LsonValue> SavedVariableFileData = ReadSavedVariableFile();
            if (SavedVariableFileData != null)
            {
                if (SavedVariableFileData.ContainsKey("NirnAuctionHouseData"))
                {
                    LsonValue item = SavedVariableFileData["NirnAuctionHouseData"]["Default"];



                    foreach (string key in item.Keys)
                {

                        LsonValue items = item[key];

                    if (items.ContainsKey("$AccountWide"))
                    {

                            LsonValue acctdata = items["$AccountWide"];
                        if (acctdata.ContainsKey("ActiveAccount"))
                        {
                            if (acctdata["ActiveAccount"] != null && (string)acctdata["ActiveAccount"] != "" && (string)acctdata["ActiveAccount"] != "\"\"")
                            {

                                    foundAccount = true;
                                    bool DoReloadTradeData = false;
                                    bool DoPostListings = false;
                                    bool DoPostBids = false;
                                    bool ReloadTradeDataTracked = false;
                                    bool DoPostFilledOrders = false;
                                    bool DoPostPaidOrders = false;

                                    try {
                                        

                                            string GameWorldName = (string)acctdata["WorldName"];
                                            GetAPIEndpoint(GameWorldName);

                                        DoPlaySounds = (bool)acctdata["PlaySounds"];
                                        DoPlaySounds_success_listing = (bool)acctdata["PlaySounds_success_listing"];
                                        DoPlaySounds_success_buy = (bool)acctdata["PlaySounds_success_buy"];
                                        DoPlaySounds_success_cancel = (bool)acctdata["PlaySounds_success_cancel"];



                                        DoActiveSellersOnly = (bool)acctdata["ActiveSellersOnly"];

                                        DoReloadTradeData = (bool)acctdata["ReloadTradeData"];
                                        DoPostListings = (bool)acctdata["PostListings"];
                                     DoPostBids = (bool)acctdata["PostBids"];
                                     ReloadTradeDataTracked = false;
                                        if (acctdata.ContainsKey("ReloadTradeDataTracked")) { ReloadTradeDataTracked = (bool)acctdata["ReloadTradeDataTracked"]; }
                                        DoPostFilledOrders = (bool)acctdata["PostFilledOrders"];
                                        DoPostPaidOrders = (bool)acctdata["PostPaidOrders"];


                                    }
                                  catch (Exception exception)
                                {
                                    this.ToLog(exception);
                                }

                                if (DoPostFilledOrders)
                                {
                                     this.StatusText = "Posting Filled Orders";
                                    label1.Text = this.StatusText;
                                    this.ParseNPostFilledOrders();

                                }
                                if (DoPostListings)
                                {
                                        this.StatusText = "Posting Listings";
                                    label1.Text = this.StatusText;
                                    this.ParseNPostListings();

                                }
                                if (DoPostBids)
                                {
                                        this.StatusText = "Posting Bids";
                                    label1.Text = this.StatusText;
                                    this.ParseNPostBids();

                                }

                                    if (ReloadTradeDataTracked)
                                    {

                                        this.UpdateTrackedBidList();
                                        this.UpdateTradeList();
                                        this.UpdateBidList();

                                    }

                                    if (DoReloadTradeData )
                                    {
                                        this.StatusText = "Reloading Trade Data";
                                        label1.Text = this.StatusText;
                                        this.UpdateTradeList();
                                        this.UpdateBidList();
                                        this.UpdateTrackedBidList();

                                    }


                                    if (DoPostPaidOrders)
                                    {
                                        this.StatusText = "Posting PaidOrders";
                                        label1.Text = this.StatusText;
                                        this.ParseNPostPaidOrders();

                                    }





                                }
                        }
                    }
                }
            }
            }

            this.StatusText = "Finished Parsing saved vars";
            label1.Text = this.StatusText;
            this.LastParseTime = DateTime.Now;

           // if (!foundAccount) {

           // }


        }


        public void ModDeactivate()
        {
            try
            {

                string modInitFile = "ModInitiate.Lua";
                if (File.Exists(modInitFile)) { File.Delete(modInitFile); }
                using (StreamWriter streamWriter = new StreamWriter(modInitFile, true))
                {
                    streamWriter.WriteLine("function NirnAuctionHouse:CheckServerLinkInitiated()");
                    streamWriter.WriteLine("");
                    streamWriter.WriteLine("end");
                }
            }
            catch (Exception exception)
            {
                this.ToLog("ModInitiate Error");
                this.ToLog(exception);
            }

        }

        public void ModInitiate(){
            try
            {

                string modInitFile = "ModInitiate.Lua";
                if (File.Exists(modInitFile)) { File.Delete(modInitFile); }
                using (StreamWriter streamWriter = new StreamWriter(modInitFile, true))
                {
                    streamWriter.WriteLine("function NirnAuctionHouse:CheckServerLinkInitiated()");
                    streamWriter.WriteLine("NirnAuctionHouse_ServerLink_INITIATED(\"0.0.0.21\")");
                    streamWriter.WriteLine("end");
                }
            }
            catch (Exception exception)
            {
                this.ToLog("ModInitiate Error");
                this.ToLog(exception);
            }

        }



        public void ModNotification(string notification)
        {
            try
            {

                string modNotificationFile = "ModNotifications.Lua";
                if (File.Exists(modNotificationFile)) { File.Delete(modNotificationFile); }
                using (StreamWriter streamWriter = new StreamWriter(modNotificationFile, true))
                {
                    streamWriter.WriteLine("function NirnAuctionHouse:CheckNotifications()");
                    if (notification!="")
                    {
                        streamWriter.WriteLine("d(GetString(" + notification + "))");
                    }
                    streamWriter.WriteLine("end");
                }
            }
            catch (Exception exception)
            {
                this.ToLog("ModNotifications Error");
                this.ToLog(exception);
            }

        }


        private void button2_Click(object sender, EventArgs e)
        {
            this.UpdateTradeList();
        }

        private void button3_Click(object sender, EventArgs e)
        {
            this.StartWatchingSavedVars();
        }

        private void button4_Click(object sender, EventArgs e)
        {
            this.ModDeactivate();
            
        }
        
       

        private void PlaySuccessSound()
        {
            if (DoPlaySounds)
            {
               SoundPlayer TaDaSound = new SoundPlayer(NirnAuctionHouse.Properties.Resources.TaDa);
            TaDaSound.Play();
            }
        }

        private void PlayFailedSound()
        {
            if (DoPlaySounds)
            {
                SoundPlayer SadTromboneSound = new SoundPlayer(NirnAuctionHouse.Properties.Resources.SadTrombone);
                SadTromboneSound.Play();
            }
        }

        private void PlayNewSoldItemsSound()
        {
            if (DoPlaySounds)
            {
                SoundPlayer SoldItemsSound = new SoundPlayer(NirnAuctionHouse.Properties.Resources.SoldItemsSound);
                SoldItemsSound.Play();
            }
        }


        private void ReloadGameBids()
        {
            this.PlayNewSoldItemsSound();            
        }




        private void HandleTimedEvents()
        {


            foundAccount = this.LoadActiveAccount();
            if (foundAccount) {
            this.GetAPIEndpoint();
            this.UpdateBidList();
            this.UpdateTradeList();
            this.UpdateTrackedBidList();


            bool newBidsFound = this.CheckNewBids();
            if (newBidsFound)
            {
                this.ReloadGameBids();//alert mod that there are new bids waiting for it                
            }
         }
        }

        private void DoTimer()
        {


        }

        public void OnTimedEvent(Object source, EventArgs e, Form1 curform)
        {

         
                this.HandleTimedEvents();
        }
        
        

        private void button5_Click(object sender, EventArgs e)
        {
            this.UpdateBidList();
        }

        private void button6_Click(object sender, EventArgs e)
        {
            this.CheckNewBids();
        }


        public bool CheckNewBids() {
            bool hasnewbid = false;
            if (ActiveAccount == "" || ActiveAccount == "\"\"")
            {
                this.LoadActiveAccount();
            }

            if (ActiveAccountUUID == null || ActiveAccountUUID == "")
            {
                this.StatusText = "Loading Active Account UUID";
                // label1.Text = this.StatusText;
                this.UpdateUUID();
            }

            if (ActiveAccount != "" && ActiveAccount != "\"\"" && ActiveAccountUUID != null && ActiveAccountUUID != "")
            {

                using (WebClient client = new WebClient())
                {
                    try
                    {
                 string BidListContent = client.DownloadString(this.APIEndpoint + "/proc/bidlist/" + ActiveAccount + "~" + ActiveAccountUUID + "/json");

                    if (BidListContent == "" || BidListContent == "[]")
                    {
                        _currentBidsData = new Dictionary<string, AuctionBidEntry>();
                    }
                    else
                    {

                        JavaScriptSerializer ser = new JavaScriptSerializer();
                        var JSONObj = ser.Deserialize<Dictionary<string, AuctionBidEntry>>(BidListContent); //JSON decoded


                        if (_currentBidsData == null) { _currentBidsData = new Dictionary<string, AuctionBidEntry>(); }
                        
                        foreach (KeyValuePair<string, AuctionBidEntry> entry in JSONObj)
                        {
                            if (!_currentBidsData.ContainsKey(entry.Key))
                            {
                                //new bid
                                hasnewbid = true;
                                this.StatusText = "Found New Bid For: " + entry.Value.Seller;
                                label1.Text = this.StatusText;
                                _currentBidsData.Add(entry.Key, entry.Value);
                            }
                        }

                    }

                    if (!hasnewbid)
                    {
                        this.StatusText = "No New Bids Found";
                        label1.Text = this.StatusText;
                    }

                    }
                    catch (Exception exception)
                    {
                        this.ToLog(exception);
                    }
                 

                }
            }
            return hasnewbid;
        }
        

        public bool LoadActiveAccount() {
            try
            {


                string str = Path.Combine(SavedVariableDirectory, "NirnAuctionHouse.lua");
                if (!File.Exists(str))
                {
                    //this.ToLog("Auction House Saved File doesnt exist yet: " + str);
                    this.StatusText = "Auction House Saved File doesnt exist yet";
                    label1.Text = this.StatusText;
                    return false;
                }
                Dictionary<string, LsonValue> SavedVariableFileData = ReadSavedVariableFile();

                

                    if (SavedVariableFileData.ContainsKey("NirnAuctionHouseData"))
                {
                   LsonValue item = SavedVariableFileData["NirnAuctionHouseData"]["Default"];

                    foreach (string key in item.Keys)
                     {
                        string tmpActiveAccount = (string)item[key]["$AccountWide"]["ActiveAccount"];                       

                    if (tmpActiveAccount != null && (string)tmpActiveAccount != "" && (string)tmpActiveAccount != "@" && (string)tmpActiveAccount != "\"\"")
                  {
                            ActiveAccount = tmpActiveAccount;
                            // this.ToLog("Account Found: " + tmpActiveAccount);
                            this.UpdateUUID();
                            return true;
                    }
                }
            }

               // this.ToLog("No Account Found");

            }
            catch (Exception exception)
            {
                this.ToLog(exception);
            }
            return false;
        }

        private void button7_Click(object sender, EventArgs e)
        {

            StartTimedEvents();

        }

        private void StartTimedEvents()
        {

            // Create a timer and set a 5 minute interval.
            aTimer = new System.Windows.Forms.Timer();
              aTimer.Interval = 300000;
           // aTimer.Interval = 60000;//one minute
            aTimer.Tick += (thesender, theE) => OnTimedEvent(thesender, theE, this);

        // Start the timer
        aTimer.Enabled = true;
            aTimer.Start();
        }

       


        private void button9_Click(object sender, EventArgs e)
        {

            try
            {          
                    this.ModInitiate();  
            }
            catch (Exception exception)
            {
                this.ToLog(exception);
            }
           
            
        }

        private void button1_Click_1(object sender, EventArgs e)
        {
            this.StatusText = "Testing Communication with server";
            label1.Text = this.StatusText;
            try
            {
               

                string ConnectionTest = this.SendPackage(this.APIEndpoint + "/proc/connectivity", " { \"isConnected\":1,\"ItemData\":{\"itemId\":33768,\"stackCount\":3,\"IsBuyout\":1,\"Item\":{\"ID\":33768,\"ItemLink\":\" | H1:item: 33768:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0 | h | h\",\"LevelTotal\":1,\"RequiredLevel\":1,\"RequiredChampionPoints\":0,\"Name\":\"Comberry\",\"Quality\":1,\"Condition\":100,\"RepairCost\":0,\"ArmorRating\":0,\"WeaponPower\":0,\"StatVal\":0,\"ItemCharge\":0,\"ItemChargeMax\":0,\"ItemChargePercent\":0,\"enchantHeader\":\"\",\"enchantDescription\":\"\",\"traitDescription\":\"\",\"traitType\":\"NONE\",\"traitSubtypeDescription\":\"\",\"traitSubtype\":\"NONE\",\"setName\":\"\",\"sellValue\":0,\"Trait\":null,\"ItemType\":10,\"ItemWeaponType\":0,\"ItemArmorType\":0},\"StartingPrice\":30,\"BuyoutPrice\":45}}");
                if (ConnectionTest== "Done!")
                {
                    PlaySuccessSound();
                    this.StatusText = "Successfully Communicated with server";
                    label1.Text = this.StatusText;
                }
                else
                {
                    //failed sound is already played by sendpackage function should teh request fail
                    this.StatusText = "Failed to Communicate with server: "+ ConnectionTest;
                    label1.Text = this.StatusText;

                }

                return;

            }
            catch (Exception exception)
            {
                this.ToLog("Connection Test Error");
                this.ToLog(exception);
            }
        }

        private void button3_Click_1(object sender, EventArgs e)
        {
            //RemoveStartup();
        }



        


        public GameServer GetGameServerFromFile()
        {
            string ParamValue = "";
            string ParamName = "";
            GameServer TmgGameServer;
            bool foundyet = false;
            string SettingsFile = Path.GetFullPath("../../UserSettings.txt");
            if (!File.Exists(SettingsFile))
            {
                return GameServer.NotFound;
            }
            using (StringReader SettingsFileReader = new StringReader(System.IO.File.ReadAllText(SettingsFile)))
            {
                do
                {
                    string LineContent = SettingsFileReader.ReadLine();
                    if (LineContent != null)
                    {
                        Match match = (new Regex("SET (.*) \"(.*)\"")).Match(LineContent);
                        if (match.Success)
                        {
                            ParamName = match.Groups[1].Value;
                            ParamValue = match.Groups[2].Value;
                            if (ParamName.ToLower() != "lastplatform")
                            {
                                if (ParamName.ToLower() == "lastrealm")
                                {
                                    if (ParamValue.StartsWith("NA"))
                                    {
                                        foundyet = true;
                                        TmgGameServer = GameServer.NA;
                                        return TmgGameServer;
                                    }
                                }
                            }
                            else if (ParamValue == "Live")
                            {
                                foundyet = true;
                                TmgGameServer = GameServer.NA;
                                return TmgGameServer;
                            }
                            else if (ParamValue == "Live-EU")
                            {
                                foundyet = true;
                                TmgGameServer = GameServer.EU;
                                return TmgGameServer;
                            }
                        }
                    }
                    else
                    {
                        foundyet = true;
                        TmgGameServer = GameServer.NotFound;
                        return GameServer.NotFound;
                    }
                }
                while (!foundyet);
                TmgGameServer = GameServer.EU;
            }
            return TmgGameServer;
        }









       







        public void ToLog(Exception e)
        {
            this.ToLog(e.ToString());
        }

        public void ToLog(string LogMessage)
        {
            try
            {
                DateTime now = DateTime.Now;
                string LogFileName = string.Concat("Log_",now.ToString("dd-MM-yy"), ".txt");
                string LogPath = Path.Combine(this.LogDir, LogFileName);
                if (!File.Exists(this.LogDir))
                {
                    Directory.CreateDirectory(this.LogDir);
                }
                using (StreamWriter streamWriter = new StreamWriter(LogPath, true))
                {
                    
                    streamWriter.WriteLine(LogMessage);
                }
            }
            catch
            {
            }
        }
        

        public string SendPackage(string Endpoint, List<AuctionPaidOrdersEntry> Package)
        {
            JavaScriptSerializer jsonSerialiser = new JavaScriptSerializer();
            string jsonPackage = jsonSerialiser.Serialize(Package);
            return SendPackage(Endpoint, jsonPackage);
        }
        public string SendPackage(string Endpoint, List<AuctionFilledOrderEntry> Package)
        {
            JavaScriptSerializer jsonSerialiser = new JavaScriptSerializer();
            string jsonPackage = jsonSerialiser.Serialize(Package);
            return SendPackage(Endpoint, jsonPackage);
        }
        public string SendPackage(string Endpoint, List<AuctionEntry> Package)
        {
            JavaScriptSerializer jsonSerialiser = new JavaScriptSerializer();
            string jsonPackage = jsonSerialiser.Serialize(Package);
            return SendPackage(Endpoint, jsonPackage);
        }

        public string SendPackage(string Endpoint, List<AuctionBidEntry> Package)
        {
            JavaScriptSerializer jsonSerialiser = new JavaScriptSerializer();
            string jsonPackage = jsonSerialiser.Serialize(Package);
            return SendPackage(Endpoint, jsonPackage);
        }


        public string SendPackage(string Endpoint, string Package)
        {




            try
            {

                string ServerResponse = "";
                var httpWebRequest = (HttpWebRequest)WebRequest.Create(Endpoint);
                httpWebRequest.ContentType = "application/json";
                httpWebRequest.Method = "POST";

                using (var streamWriter = new StreamWriter(httpWebRequest.GetRequestStream()))
                {
                    streamWriter.Write(Package);
                    streamWriter.Flush();
                    streamWriter.Close();
                }

                var httpResponse = (HttpWebResponse)httpWebRequest.GetResponse();
                var streamReader = new StreamReader(httpResponse.GetResponseStream());
                    ServerResponse = streamReader.ReadToEnd();
                    if (ServerResponse == "The resource is created successfully!" || ServerResponse == "Done!")
                    {
                        // this.ToLog("Package Successfully Sent");
                    }
                    else
                     {
                    PlayFailedSound();
                    this.ToLog("sending Package to: " + Endpoint);
                    this.ToLog("sending Package: " + Package);
                    this.ToLog("SendPackage: " + ServerResponse);
                    }
                    return ServerResponse;
               
            }
            catch (Exception ex)
            {
                PlayFailedSound();
                this.ToLog(ex.Message);
            }
            return "";
        }



        public Dictionary<string, LsonValue> ReadSavedVariableFile()
        {

            LsonVars.Parse(File.ReadAllText(Path.Combine(SavedVariableDirectory, "NirnAuctionHouse.lua")));

            Dictionary<string,LsonValue> SavedVariableFileData = LsonVars.Parse(File.ReadAllText(Path.Combine(SavedVariableDirectory, "NirnAuctionHouse.lua"))); ;
           
            
            return SavedVariableFileData;


        }



        private void OnApplicationExit(object sender, EventArgs e)
        {

            try
            {
                this.ModDeactivate();
                this.ModNotification("");
            }
            catch (Exception exception)
            {
                this.ToLog(exception);
            }
        }


    }















}
