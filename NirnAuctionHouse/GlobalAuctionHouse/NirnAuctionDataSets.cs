using System.Collections.Generic;
using System.Runtime.Serialization;
using LuaTableHandlers;

namespace GlobalAuctionHouse
{
    public class AuctionTradeData
    {

        public string Name
        {
            get;
            set;
        }

        public List<AuctionEntry> AuctionEntries
        {
            get;
            set;
        }

        public AuctionTradeData()
        {
        }

        public AuctionTradeData(string name)
        {
            this.Name = name;
            this.AuctionEntries = new List<AuctionEntry>();
        }

        public static AuctionTradeData LoadFromSavedVars(LsonValue luaObject, string CharName)
        {

            LsonValue items = luaObject;
            if (items.ContainsKey("$AccountWide"))
            {
                LsonValue acctdata = items["$AccountWide"];

                    LsonValue item = (acctdata)["data"]["Listings"];
                    List<AuctionEntry> CurAuctionEntries = new List<AuctionEntry>();
                        foreach (int key in item.Keys)
                        {
                            LsonValue tmpdict = item[key];
                            if (tmpdict.ContainsKey("attributes") && tmpdict.ContainsKey("Listing"))
                            {
                             AuctionEntry CurAuctionEntry = new AuctionEntry(tmpdict, CharName);
                                if (!CurAuctionEntry.ItemData.Item.ID.HasValue)
                                {
                                    continue;
                                }
                        CurAuctionEntries.Add(CurAuctionEntry);
                        }
                    }
                    return new AuctionTradeData(CharName)
                    {
                        AuctionEntries = CurAuctionEntries
                    };
        }

            return new AuctionTradeData(CharName)
            {

            };
        }





    }













    [DataContract]
    public class AuctionItemData
    {

        [DataMember]
        public string CharName
        {
            get;
            set;
        }

        [DataMember]
        public int itemId
        {
            get;
            set;
        }

        [DataMember]
        public int stackCount
        {
            get;
            set;
        }

        [DataMember]
        public int IsBuyout
        {
            get;
            set;
        }

        [DataMember]
        public AuctionItem Item
        {
            get;
            set;
        }


        [DataMember]
        public int StartingPrice
        {
            get;
            set;
        }

        [DataMember]
        public int BuyoutPrice
        {
            get;
            set;
        }

        public AuctionItemData()
        {
        }

        public AuctionItemData(LsonValue luaObject)
        {
            int i;
            if (luaObject.ContainsKey("attributes") && luaObject.ContainsKey("Listing"))
            {
                LsonValue curAttributes = (luaObject["attributes"]);
                LsonValue curListing = (luaObject["Listing"]);

                if (curAttributes.ContainsKey("itemId") && curAttributes.ContainsKey("stackCount") && curListing.ContainsKey("Price"))
                {
                    this.Item = new AuctionItem(luaObject);
                    this.StartingPrice = 0;
                    this.BuyoutPrice = 0;

                    
                    this.stackCount = (int)curAttributes["stackCount"];

                    if (!int.TryParse((string)curAttributes["itemId"], out i)) i = 0;
                    this.itemId = i;
                    // this.itemId = (int)curAttributes["itemId"];

                    if (curListing.ContainsKey("Player"))
                    {
                        
                            this.CharName = (string)curListing["Player"];
                    }


                    if (curListing.ContainsKey("BuyoutPrice"))
                    {


                        //this.BuyoutPrice = (int)curListing["BuyoutPrice"];
                        string tmpbuyout = (string)curListing["BuyoutPrice"];
                        if (tmpbuyout != "" && tmpbuyout != "\"\"")
                        {
                            if (!int.TryParse(tmpbuyout, out i)) i = 0;
                            this.BuyoutPrice = i;
                        }
                    }


                    if (curListing.ContainsKey("StartingPrice"))
                    {
                        
                        string tmpprice = (string)curListing["StartingPrice"];
                        if (tmpprice != "" && tmpprice != "\"\"")
                        {
                            if (!int.TryParse(tmpprice, out i)) i = 0;
                            this.StartingPrice = i;
                        }
                    }
                    else
                    {
                        this.StartingPrice = this.BuyoutPrice;

                    }


                    if (curListing.ContainsKey("IsBuyout"))
                    {
                        this.IsBuyout = (int)curListing["IsBuyout"];
                    }
                }
            }
        }

        

    }





    [DataContract]
    public class AuctionItem
    {

        [DataMember(EmitDefaultValue = false)]
        public int? ID
        {
            get;
            set;
        }

        [DataMember]
        public string ItemLink
        {
            get;
            set;
        }

        [DataMember]
        public int LevelTotal
        {
            get;
            set;
        }



        [DataMember]
        public int RequiredLevel
        {
            get;
            set;
        }


        [DataMember]
        public int RequiredChampionPoints
        {
            get;
            set;
        }


        [DataMember]
        public string Name
        {
            get;
            set;
        }
        

        [DataMember]
        public int Quality
        {
            get;
            set;
        }




        [DataMember]
        public int Condition
        {
            get;
            set;
        }


        [DataMember]
        public int RepairCost
        {
            get;
            set;
        }


        [DataMember]
        public int ArmorRating
        {
            get;
            set;
        }



        [DataMember]
        public int WeaponPower
        {
            get;
            set;
        }




        [DataMember]
        public int StatVal
        {
            get;
            set;
        }

        [DataMember]
        public int ItemCharge
        {
            get;
            set;
        }

        [DataMember]
        public int ItemChargeMax
        {
            get;
            set;
        }


        [DataMember]
        public int ItemChargePercent
        {
            get;
            set;
        }


        [DataMember]
        public string enchantHeader
        {
            get;
            set;
        }


        [DataMember]
        public string enchantDescription
        {
            get;
            set;
        }


        [DataMember]
        public string traitDescription
        {
            get;
            set;
        }



        [DataMember]
        public string traitType
        {
            get;
            set;
        }



        [DataMember]
        public string traitSubtypeDescription
        {
            get;
            set;
        }



        [DataMember]
        public string traitSubtype
        {
            get;
            set;
        }


        [DataMember]
        public string setName
        {
            get;
            set;
        }

        [DataMember]
        public int sellValue
        {
            get;
            set;
        }




        [DataMember(EmitDefaultValue = false)]
        public int? Trait
        {
            get;
            set;
        }


        [DataMember(EmitDefaultValue = false)]
        public int? ItemType
        {
            get;
            set;
        }

        [DataMember(EmitDefaultValue = false)]
        public int? ItemWeaponType
        {
            get;
            set;
        }

        [DataMember(EmitDefaultValue = false)]
        public int? ItemArmorType
        {
            get;
            set;
        }

        public AuctionItem()
        {
        }

        public AuctionItem(LsonValue luaObject)
        {
            
            LsonValue curAttributes = (luaObject["attributes"]);
            LsonValue curListing = (luaObject["Listing"]);

            LsonValue curType = (curAttributes["Type"]);
            LsonValue curCondition = (curAttributes["Condition"]);
            LsonValue curTrait = (curAttributes["Trait"]);
            LsonValue curEnchant = (curAttributes["Enchant"]);

            this.ItemType = (int)curType["ItemType"];
            this.ItemWeaponType =(int)curType["ItemWeaponType"];
            this.ItemArmorType = (int)curType["ItemArmorType"];
            this.ItemLink = ToUTF8((string)curAttributes["ItemLink"]);
            this.Name = ToUTF8((string)curAttributes["itemName"]);
            int? nullable = null;
            this.ID = nullable;
            if (curAttributes.ContainsKey("itemId"))
            {
                this.ID = new int?(int.Parse((string)curAttributes["itemId"]));
            }
            this.Quality = (int)curAttributes["itemQuality"];

            this.Condition = (int)curCondition["ItemCondition"];
            this.RepairCost = (int)curCondition["ItemRepairCost"];


            this.ArmorRating = (int)curAttributes["ItemArmorRating"];
            this.WeaponPower = (int)curAttributes["ItemWeaponPower"];
            this.StatVal = (int)curAttributes["itemStatVal"];


            this.ItemCharge = (int)curEnchant["ItemCharge"];
            this.ItemChargeMax = (int)curEnchant["ItemChargeMax"];
            this.ItemChargePercent = (int)curEnchant["ItemChargePercent"];
            this.enchantHeader = (string)curEnchant["enchantHeader"];
            this.enchantDescription = (string)curEnchant["enchantDescription"];



            this.traitDescription = (string)curTrait["traitDescription"];
            this.traitType = (string)curTrait["traitType"];
            if (curTrait.ContainsKey("traitSubtypeDescription"))
            {
                this.traitSubtypeDescription = (string)curTrait["traitSubtypeDescription"];
            }else
            {
                this.traitSubtypeDescription = "";
            }
            this.traitSubtype = (string)curTrait["traitSubtype"];

            this.setName = (string)curAttributes["setName"];


            this.sellValue = (int)curCondition["ItemSellValueWithBonuses"];




            this.RequiredLevel = (int)curAttributes["ItemRequiredLevel"];
            this.RequiredChampionPoints = (int)curAttributes["ItemRequiredChampionPoints"];
            this.LevelTotal = this.RequiredLevel + this.RequiredChampionPoints;
            

        }




        public static string ToUTF8(string plainText)
        {
            var plainTextBytes = System.Text.Encoding.UTF8.GetBytes(plainText);
            return System.Text.Encoding.UTF8.GetString(plainTextBytes);
        }




    }



    [DataContract]
    public class AuctionFilledOrderEntry
    {

        [DataMember(EmitDefaultValue = false)]
        public int? TradeID
        {
            get;
            set;
        }

        [DataMember]
        public string ActiveAccountData
        {
            get;
            set;
        }

        [DataMember]
        public int? BidID
        {
            get;
            set;
        }

        public int? ID
        {
            get;
            set;
        }


        public AuctionFilledOrderEntry()
        {
        }

        public AuctionFilledOrderEntry(LsonValue luaObject, string ActiveAccountcreds)
        {
            // try{

                this.ActiveAccountData = ActiveAccountcreds;
                luaObject = luaObject["Order"];
            int i = 0;
            if (!int.TryParse((string)luaObject["TradeID"], out i)) i = 0;
            this.TradeID = i;


            if (!int.TryParse((string)luaObject["BidID"], out i)) i = 0;
            this.BidID = i;
            //this.BidID = (int)luaObject["BidID"];
            // }catch(){
            //}
        }


    }













    [DataContract]
    public class AuctionEntry
    {

        [DataMember(EmitDefaultValue = false)]
        public string CharName
        {
            get;
            set;
        }        

        [DataMember]
        public AuctionItemData ItemData
        {
            get;
            set;
        }

        public AuctionEntry()
        {
        }

        public AuctionEntry(LsonValue luaObject, string CharName)
        {
            this.ItemData = new AuctionItemData(luaObject);
            this.CharName = CharName;
        }


    }






    





    [DataContract]
    public class AuctionBidEntry
    {

        [DataMember(EmitDefaultValue = false)]
        public int? TradeID
        {
            get;
            set;
        }

        [DataMember]
        public int? ItemID
        {
            get;
            set;
        }
        [DataMember]
        public string Seller
        {
            get;
            set;
        }

        [DataMember]
        public string Buyer
        {
            get;
            set;
        }

        [DataMember]
        public string ItemLink
        {
            get;
            set;
        }

        [DataMember]
        public int Price
        {
            get;
            set;
        }


        [DataMember]
        public int stackCount
        {
            get;
            set;
        }


        public AuctionBidEntry()
        {
        }

        public AuctionBidEntry(LsonValue luaObject, string CharName)
        {

            luaObject = luaObject["Bid"];

            this.Buyer = CharName;
            this.Seller = (string)luaObject["seller"];
            int i;
            if (!int.TryParse((string)luaObject["TradeID"], out i)) i = 0;
            this.TradeID = i;
            this.ItemID = (int)luaObject["ItemID"];
            this.ItemLink = (string)luaObject["ItemLink"];
            this.stackCount = (int)luaObject["stackCount"];
            this.Price = (int)luaObject["Price"];
        }


    }





    [DataContract]
    public class AuctionPaidOrdersEntry
    {
        

        [DataMember(EmitDefaultValue = false)]
        public int? ItemID
        {
            get;
            set;
        }
        [DataMember]
        public string Seller
        {
            get;
            set;
        }

        [DataMember]
        public string Buyer
        {
            get;
            set;
        }
        

        [DataMember]
        public int codAmount
        {
            get;
            set;
        }

        [DataMember]
        public int Price
        {
            get;
            set;
        }


        [DataMember]
        public int stackCount
        {
            get;
            set;
        }

        [DataMember]
        public int itemQuality
        {
            get;
            set;
        }

        [DataMember]
        public string mailId
        {
            get;
            set;
        }


        public AuctionPaidOrdersEntry()
        {
        }

        public AuctionPaidOrdersEntry(LsonValue luaObject, string CharName)
        {
            

            this.Buyer = CharName;
            this.Seller = (string)luaObject["Seller"];
            this.mailId = (string)luaObject["mailId"];
            int i;
            if (!int.TryParse((string)luaObject["ItemID"], out i)) i = 0;
            this.ItemID = i;
            this.stackCount = (int)luaObject["stack"];
            this.Price = (int)luaObject["sellPrice"];
            this.codAmount = (int)luaObject["codAmount"];
            this.itemQuality = (int)luaObject["itemQuality"];
        }


    }








}
