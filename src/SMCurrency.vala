//                                         
//   _____     _   _____ _       _         
//  |   __|_ _| |_|     |_|___ _| |___ ___ 
//  |__   | | | . | | | | |   | . | -_|  _|
//  |_____|___|___|_|_|_|_|_|_|___|___|_|  
//                                         
//                            Version 1.0.0
//  
//        Jeremy Vaartjes<jeremy@vaartj.es>
//  
//  =======================================
//  
//  Copyright (C) 2019 Jeremy Vaartjes
//  
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//  
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//  
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
//  
//  =======================================
//  

public class SMCurrency {
    public Gee.TreeMap<string, string> currencies;
    public Gee.TreeMap<string, double?> currencyPrices;
    public bool dbNeedsUpdate;

    public SMCurrency() throws IOError, Error{
        dbNeedsUpdate = false;
        currencies = new Gee.TreeMap<string, string>();
        currencyPrices = new Gee.TreeMap<string, double?>();
        var cFile = File.new_for_path(Environment.get_user_data_dir() + "/com.github.jeremyvaartjes.subminder/currency/currency.json");
        var acFile = File.new_for_path(Environment.get_user_data_dir() + "/com.github.jeremyvaartjes.subminder/currency/availablecurrencies.json");
        if (!cFile.query_exists () || !acFile.query_exists ()){
            download();
        }

        if (!cFile.query_exists () || !acFile.query_exists ()){
            throw new IOError.NOT_FOUND(_("Cannot load currency data"));
        }else{
            Json.Parser timeParser = new Json.Parser ();
            timeParser.load_from_file (Environment.get_user_data_dir() + "/com.github.jeremyvaartjes.subminder/currency/currency.json");
            Json.Node node = timeParser.get_root ();
            Json.Object timeObj = node.get_object ();
            var genTime = new DateTime.from_unix_utc (timeObj.get_int_member ("timestamp"));
            var curTime = new DateTime.now_utc();
            var timeSince = curTime.difference(genTime);
            if(timeSince > 6.5 * TimeSpan.HOUR){
                stdout.printf(_("Downloading updated currency data...\n"));
                ThreadFunc<bool> run = () => {
                    download();
                    try{
                        Json.Parser acParser = new Json.Parser ();
                        acParser.load_from_file (Environment.get_user_data_dir() + "/com.github.jeremyvaartjes.subminder/currency/availablecurrencies.json");
                        node = acParser.get_root ();
                        Json.Object acObj = node.get_object ();
                        acObj = acObj.get_object_member ("symbols");

                        Json.Parser cParser = new Json.Parser ();
                        cParser.load_from_file (Environment.get_user_data_dir() + "/com.github.jeremyvaartjes.subminder/currency/currency.json");
                        node = cParser.get_root ();
                        Json.Object cObj = node.get_object ();
                        cObj = cObj.get_object_member ("rates");

                        acObj.foreach_member((obj, member_name, member_node) => {
                            currencies[member_name] = obj.get_string_member (member_name);
                            currencyPrices[member_name] = cObj.get_double_member (member_name);
                        });
                    }catch(Error e){
                        stderr.printf ("Error: %s\n", e.message);
                        return false;
                    }
                    return true;
                };
                new Thread<bool>("Currency Download", run);
            }

            Json.Parser acParser = new Json.Parser ();
            acParser.load_from_file (Environment.get_user_data_dir() + "/com.github.jeremyvaartjes.subminder/currency/availablecurrencies.json");
            node = acParser.get_root ();
            Json.Object acObj = node.get_object ();
            acObj = acObj.get_object_member ("symbols");

            Json.Parser cParser = new Json.Parser ();
            cParser.load_from_file (Environment.get_user_data_dir() + "/com.github.jeremyvaartjes.subminder/currency/currency.json");
            node = cParser.get_root ();
            Json.Object cObj = node.get_object ();
            cObj = cObj.get_object_member ("rates");

            acObj.foreach_member((obj, member_name, member_node) => {
                currencies[member_name] = obj.get_string_member (member_name);
                currencyPrices[member_name] = cObj.get_double_member (member_name);
            });
        }
    }

    public void download(){
        try {
            var dir = File.new_for_path(Environment.get_user_data_dir() + "/com.github.jeremyvaartjes.subminder/currency");
            if (!dir.query_exists ()){
                dir.make_directory_with_parents ();
            }

            Soup.Session session = new Soup.Session ();
            Soup.Request request = session.request ("https://jeremy.vaartj.es/currency.json");
            InputStream stream = request.send ();
            DataInputStream data_stream = new DataInputStream (stream);
            string? line;
            string cDat = "";
            while ((line = data_stream.read_line ()) != null) {
                cDat += line + "\n";
            }
            request = session.request ("https://jeremy.vaartj.es/availablecurrencies.json");
            stream = request.send ();
            data_stream = new DataInputStream (stream);
            string acDat = "";
            while ((line = data_stream.read_line ()) != null) {
                acDat += line + "\n";
            }

            var cFile = File.new_for_path(Environment.get_user_data_dir() + "/com.github.jeremyvaartjes.subminder/currency/currency.json");
            var acFile = File.new_for_path(Environment.get_user_data_dir() + "/com.github.jeremyvaartjes.subminder/currency/availablecurrencies.json");
            FileOutputStream cOS;
            if (!cFile.query_exists ()){
                cOS = cFile.create(FileCreateFlags.NONE);
            }else{
                cOS = cFile.replace(null, false, FileCreateFlags.NONE);
            }
            FileOutputStream acOS;
            if (!cFile.query_exists ()){
                acOS = acFile.create(FileCreateFlags.NONE);
            }else{
                acOS = acFile.replace(null, false, FileCreateFlags.NONE);
            }

            cOS.write(cDat.data);
            acOS.write(acDat.data);
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
        }
    }
}