using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using System.IO;
using LuaTableHandlers;
using System.Web.Script.Serialization;
using System.Diagnostics;
using System.Net;
using System.Text.RegularExpressions;


using System.Runtime.InteropServices;
using IWshRuntimeLibrary;
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
        

        private string LastSyncTimeString;
        private DateTime LastSyncTime;

        private static System.Windows.Forms.Timer aTimer;

        private DateTime LastSyncTimeBid;
        private DateTime LastSyncTimeFOs;
        
        
        private Dictionary<string, AuctionBidEntry> _currentBidsData;

        private string ActiveAccount = "";


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
            this.StartWatchingSavedVars();
            
      

        }


        private void GetAPIEndpoint()
        {
            this.CurGameServer = this.GetGameServerFromFile();
            if (this.CurGameServer==GameServer.NA)
            {
               this.APIEndpoint = new Uri("https://nirnah.com");
            } else
            {
                this.APIEndpoint = new Uri("https://nirnah.com/eu");
            }

        }

        private void SetStartup()
        {

            WshShell wshShell = new WshShell();



            IWshRuntimeLibrary.IWshShortcut shortcut;
            string startUpFolderPath =
              Environment.GetFolderPath(Environment.SpecialFolder.Startup);

            // Create the shortcut
            shortcut =
              (IWshRuntimeLibrary.IWshShortcut)wshShell.CreateShortcut(
                startUpFolderPath + "\\" +
                Application.ProductName + ".lnk");

            shortcut.TargetPath = Application.ExecutablePath;
            shortcut.WorkingDirectory = Application.StartupPath;
            shortcut.Description = "Launch Nirn Auction House";
            shortcut.Save();

        }


        private void RemoveStartup()
        {
            string startUpFolderPath =
              Environment.GetFolderPath(Environment.SpecialFolder.Startup);

            if (File.Exists(startUpFolderPath + "\\" + Application.ProductName + ".lnk"))
            {
                File.Delete(startUpFolderPath + "\\" + Application.ProductName + ".lnk");
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
                if (totalTimeTaken.TotalMilliseconds > 2000)
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


            if (ActiveAccount == "" || ActiveAccount == "@" || ActiveAccount == "\"\"")
            {
                this.ToLog("ParseNPostListings no active account");
                return;
            }

            

            this.StatusText = "Preparing Upload";
            label1.Text = this.StatusText;
            string str = Path.Combine(SavedVariableDirectory, "NirnAuctionHouse.lua");
            if (!File.Exists(str))
            {
                this.ToLog("Auction House Saved File doesnt exist yet: " + str);
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
                            
                                    

                                    AuctionTradeData FirstAuctionTradeData = AuctionTradeData.LoadFromSavedVars(item[ActiveAccount], ActiveAccount);


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
                if (totalTimeTaken.TotalMilliseconds > 2000)
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


            if (ActiveAccount == "" || ActiveAccount == "@" || ActiveAccount == "\"\"") { return; }

            //for debugging
            //this.LastSyncTime = DateTime.Now;
            //return;

            this.StatusText = "Preparing Upload";
            label1.Text = this.StatusText;
            string str = Path.Combine(SavedVariableDirectory, "NirnAuctionHouse.lua");
            if (!File.Exists(str))
            {
                this.ToLog("Auction House Saved File doesnt exist yet: " + str);
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
                                        AuctionFilledOrderEntry TmpFilledOrder = new AuctionFilledOrderEntry(Bitem[key]);
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
                if (totalTimeTaken.TotalMilliseconds > 2000)
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


            if (ActiveAccount == "" || ActiveAccount == "@" || ActiveAccount == "\"\"") { return; }

            //for debugging
            //this.LastSyncTime = DateTime.Now;
            //return;

            this.StatusText = "Preparing Upload";
            label1.Text = this.StatusText;
            string str = Path.Combine(SavedVariableDirectory, "NirnAuctionHouse.lua");
            if (!File.Exists(str))
            {
                this.ToLog("Auction House Saved File doesnt exist yet: " + str);
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
                                        AuctionBidEntry tmpAuctionBidEntry = new AuctionBidEntry(Bitem[key], ActiveAccount);
                                        if (tmpAuctionBidEntry.ItemLink != "")
                                        {
                                    tmpAuctionBidEntries.Add(tmpAuctionBidEntry);
                                        }
                                    }






                                    AuctionBidEntry FirstAuctionBidEntry = tmpAuctionBidEntries.FirstOrDefault<AuctionBidEntry>((AuctionBidEntry x) => x.Buyer == ActiveAccount);


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
                
                string str = this.SendPackage(this.APIEndpoint + "/proc/trade/new", tradeModels.ToList<AuctionEntry>());

                this.StatusText = "result: " + str;
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
                
                string str = this.SendPackage(this.APIEndpoint + "/proc/trade/filled", tradeModels.ToList<AuctionFilledOrderEntry>());

                this.StatusText = "result: " + str;
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
                
                string str = this.SendPackage(this.APIEndpoint + "/proc/bid/new", tradeModels.ToList<AuctionBidEntry>());

                this.StatusText = "result: " + str;
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


        

        private void Form1_Load(object sender, EventArgs e)
        {

        }


        private void UpdateTradeList()
        {
            try
            {
              using (WebClient client = new WebClient()) {
                string TradeListContent = client.DownloadString(this.APIEndpoint + "/proc/tradelist");
                File.WriteAllText(this.TradeListPath, TradeListContent);
            }

            }
            catch (Exception exception)
            {
                this.ToLog(exception);
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



            if (ActiveAccount != "" && ActiveAccount != "@" && ActiveAccount != "\"\"")
            {
                try
                {

                    using (WebClient client = new WebClient())
                    {
                        
                        string BidListContent = client.DownloadString(this.APIEndpoint + "/proc/bidlist/" + ActiveAccount);
                        File.WriteAllText(this.BidListPath, BidListContent);
                        
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



            if (ActiveAccount != "" && ActiveAccount != "\"\"")
            {
                try
                {

                    using (WebClient client = new WebClient())
                    {
                        
                        string TrackedBidListContent = client.DownloadString(this.APIEndpoint + "/proc/mybidlist/" + ActiveAccount);
                        File.WriteAllText(this.TrackedBidListPath, TrackedBidListContent);

                        this.StatusText = "Updated Tracked Bid List";
                       // label1.Text = this.StatusText;
                    }

                }
                catch (Exception exception)
                {
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



            FileSystemWatcher _watcher2 = new FileSystemWatcher();
            _watcher2.Path = LivePathDirectory;
            _watcher.NotifyFilter = NotifyFilters.LastWrite;
            _watcher2.Filter = "UserSettings.txt";
            // Add event handlers.
            _watcher2.Changed += new FileSystemEventHandler(this.OnChangedSavedVars);
            _watcher2.Created += new FileSystemEventHandler(this.OnChangedSavedVars);
            // Begin watching.
            _watcher2.EnableRaisingEvents = true;

            this.StatusText = "Start Watching Saved Vars";
            label1.Text = this.StatusText;
        }

        public void parseSavedVars()
        {

            this.StatusText = "parsing saved vars";
            label1.Text = this.StatusText;

            string str = Path.Combine(SavedVariableDirectory, "NirnAuctionHouse.lua");
            if (!File.Exists(str))
            {
                this.ToLog("Auction House Saved File doesnt exist yet: " + str);
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

                                    bool DoReloadTradeData = false;
                                    bool DoPostListings = false;
                                    bool DoPostBids = false;
                                    bool ReloadTradeDataTracked = false;
                                    bool DoPostFilledOrders = false;

                                    try { 

                                 DoReloadTradeData = (bool)acctdata["ReloadTradeData"];
                                 DoPostListings = (bool)acctdata["PostListings"];
                                     DoPostBids = (bool)acctdata["PostBids"];
                                     ReloadTradeDataTracked = false;
                                        if (acctdata.ContainsKey("ReloadTradeDataTracked")) { ReloadTradeDataTracked = (bool)acctdata["ReloadTradeDataTracked"]; } 
                                     DoPostFilledOrders = (bool)acctdata["PostFilledOrders"];


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

                                    



                                }
                        }
                    }
                }
            }
            }

            this.StatusText = "Finished Parsing saved vars";
            label1.Text = this.StatusText;

            
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
                    streamWriter.WriteLine("NirnAuctionHouse_ServerLink_INITIATED( )");
                    streamWriter.WriteLine("end");
                }
            }
            catch (Exception exception)
            {
                this.ToLog("ModInitiate Error");
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


        private void PlayNewSoldItemsSound()
        {     
            SoundPlayer SoldItemsSound = new SoundPlayer(NirnAuctionHouse.Properties.Resources.SoldItemsSound);
            SoldItemsSound.Play();
        }


        private void ReloadGameBids()
        {
            this.PlayNewSoldItemsSound();            
        }

       


        private void HandleTimedEvents()
        {
            
            this.GetAPIEndpoint();
            this.LoadActiveAccount();
            this.UpdateBidList();
            this.UpdateTradeList();
            this.UpdateTrackedBidList();

         
            bool newBidsFound = this.CheckNewBids();
                if (newBidsFound)
                {
                    this.ReloadGameBids();//alert mod that there are new bids waiting for it                
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


            if (ActiveAccount != "" && ActiveAccount != "\"\"")
            {

                using (WebClient client = new WebClient())
                {
                    try
                    {
                 string BidListContent = client.DownloadString(this.APIEndpoint + "/proc/bidlist/" + ActiveAccount + "/json");
                    //File.WriteAllText(Constants.BidListPath, BidListContent);

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
        

        public void LoadActiveAccount() {
            try
            {


                string str = Path.Combine(SavedVariableDirectory, "NirnAuctionHouse.lua");
                if (!File.Exists(str))
                {
                    this.ToLog("Auction House Saved File doesnt exist yet: " + str);
                    this.StatusText = "Auction House Saved File doesnt exist yet";
                    label1.Text = this.StatusText;
                    return;
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
                            return;
                    }
                }
            }

               // this.ToLog("No Account Found");

            }
            catch (Exception exception)
            {
                this.ToLog(exception);
            }
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
            SetStartup();
        }

        private void button3_Click_1(object sender, EventArgs e)
        {
            RemoveStartup();
        }







        public static string GetAccountName()
        {
            string ParamValue = "";
            string ParamName="";
            string SettingsFile = Path.GetFullPath("../../UserSettings.txt");
            if (!File.Exists(SettingsFile))
            {
                return "";
            }
            using (StringReader SettingsFileReader = new StringReader(System.IO.File.ReadAllText(SettingsFile)))
            {
                do
                {
                    string LineContent = SettingsFileReader.ReadLine();
                    if (LineContent != null)
                    {
                        Match ISSettings = (new Regex("SET (.*) \"(.*)\"")).Match(LineContent);
                        if (ISSettings.Success)
                        {
                            ParamName = ISSettings.Groups[1].Value;
                            ParamValue = ISSettings.Groups[2].Value;
                            if (ParamName.ToLower() == "accountname")
                            {
                                return "@" + ParamValue;
                            }

                        }
                    }
                    else
                    {
                        return "";
                    }
                }
                while (ParamName.ToLower() != "accountname");
            }
            return "";
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
                using (var client = new WebClient())
                {
                    ServerResponse = client.UploadString(Endpoint, Package);

                    if (ServerResponse == "The resource is created successfully!" || ServerResponse == "Done!")
                    {
                       // this.ToLog("Package Successfully Sent");
                    }
                    else
                    {
                        this.ToLog("sending Package to: " + Endpoint);
                        this.ToLog("SendPackage: " + ServerResponse);
                    }
                    return ServerResponse;

                }                             
               
            }
            catch (Exception ex)
            {
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
            }
            catch (Exception exception)
            {
                this.ToLog(exception);
            }
        }


    }















}
