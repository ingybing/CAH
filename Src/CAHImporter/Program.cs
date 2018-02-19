using CardsAgainstHumanity.DataAccess;
using CardsAgainstHumanity.DataAccess.Documents;
using System;
using System.IO;

namespace CardsAgainstHumanity.Importer
{
    class Program
    {
        static void Main(string[] args)
        {
            if (args.Length != 2)
            {
                PrintUsage();

            }
            else
            {
                var whiteListInfo = new FileInfo(args[0]);
                var blackListInfo = new FileInfo(args[1]);

                if(!whiteListInfo.Exists)
                {
                    PrintNotFound("White List");
                }

                if (!blackListInfo.Exists)
                {
                    PrintNotFound("Black List");
                }

                if(whiteListInfo.Exists && blackListInfo.Exists)
                {
                    var storage = new Storage();
                    
                    storage.ImportCards(File.ReadAllLines(whiteListInfo.FullName), CardType.White);
                    storage.ImportCards(File.ReadAllLines(blackListInfo.FullName), CardType.Black);
                }
            }
        }
        
        private static void PrintNotFound(string v)
        {
            Console.WriteLine(string.Format("{0} was not found. Check the path and please try again."));
            PrintUsage();
        }

        private static void PrintUsage()
        {
            Console.WriteLine("Usage: CAHImporter <WhiteList.csv path> <BlackList.csv Path>");
            Console.ReadKey();
        }
    }
}
