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

public enum IntervalType {
    DAY,
    WEEK,
    MONTH,
    YEAR
}

public struct Interval {
    int qty;
    IntervalType type;
}

public class Subscription {
    private int _fileId;
    private DateTime _firstBillDate;
    private Interval _cycle;

    public string name;
    public string description;
    public DateTime firstBillDate {
        get{
            return _firstBillDate;
        }
        set{
            _firstBillDate = value;
            updateNextDates();
        }
    }
    public DateTime nextBillDate;
    public Interval cycle{
        get{
            return _cycle;
        }
        set {
            _cycle = value;
            updateNextDates();
            /*switch (_cycle.type) {
                case DAY:
                    nextBillDate = _previousBillDate.add_days(_cycle.qty);
                    break;
                case WEEK:
                    nextBillDate = _previousBillDate.add_weeks(_cycle.qty);
                    break;
                case MONTH:
                    nextBillDate = _previousBillDate.add_months(_cycle.qty);
                    break;
                case YEAR:
                    nextBillDate = _previousBillDate.add_years(_cycle.qty);
                    break;
            }*/
        }
    }
    
    public DateTime nextNotification;
    public Interval remindMe;
    public string currency;
    public int amount;
    public int fileId { get{ return _fileId; } }
    private static string subDir = "";

    public Subscription (){
        subDir = Environment.get_user_data_dir() + "/com.github.jeremyvaartjes.subminder";
        name = "";
        description = "";
        nextBillDate = new DateTime.now_local ();
        nextNotification = new DateTime.now_local ();
        _cycle = { 1, IntervalType.MONTH };
        remindMe = { 0, IntervalType.DAY };
        _firstBillDate = new DateTime.now_local ();
        currency = "";
        amount = 0;
    }

    public void write() throws Error{
        Json.Builder builder = new Json.Builder ();
        builder.begin_object ();
        builder.set_member_name ("name");
        builder.add_string_value (name);
        builder.set_member_name ("description");
        builder.add_string_value (description);
        builder.set_member_name ("firstBillDate");
        builder.begin_object ();
        builder.set_member_name ("year");
        builder.add_int_value (firstBillDate.get_year());
        builder.set_member_name ("month");
        builder.add_int_value (firstBillDate.get_month());
        builder.set_member_name ("day");
        builder.add_int_value (firstBillDate.get_day_of_month());
        builder.end_object ();
        builder.set_member_name ("cycle");
        builder.begin_object ();
        builder.set_member_name ("qty");
        builder.add_int_value (cycle.qty);
        builder.set_member_name ("type");
        switch (cycle.type) {
            case DAY:
                builder.add_string_value ("Day");
                break;
            case WEEK:
                builder.add_string_value ("Week");
                break;
            case MONTH:
                builder.add_string_value ("Month");
                break;
            case YEAR:
                builder.add_string_value ("Year");
                break;
            default:
                throw new IOError.INVALID_DATA("Invalid interval type");
        }
        builder.end_object ();
        builder.set_member_name ("remindMe");
        builder.begin_object ();
        builder.set_member_name ("qty");
        builder.add_int_value (remindMe.qty);
        builder.set_member_name ("type");
        switch (remindMe.type) {
            case DAY:
                builder.add_string_value ("Day");
                break;
            case WEEK:
                builder.add_string_value ("Week");
                break;
            case MONTH:
                builder.add_string_value ("Month");
                break;
            case YEAR:
                builder.add_string_value ("Year");
                break;
            default:
                throw new IOError.INVALID_DATA("Invalid interval type");
        }
        builder.end_object ();
        builder.set_member_name ("currency");
        builder.add_string_value (currency);
        builder.set_member_name ("amount");
        builder.add_int_value (amount);
        builder.end_object ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);
        generator.to_file(subDir + "/" + _fileId.to_string());
    }

    public void newFile() throws Error{
        var counter = 1;
        var done = false;
        while(!done){
            var file = File.new_for_path(subDir + "/" + counter.to_string());
            if (!file.query_exists ()){
                var dir = File.new_for_path(subDir);
                if (!dir.query_exists ()){
                    dir.make_directory_with_parents ();
                }

                file.create(FileCreateFlags.NONE);
                _fileId = counter;

                write();

                done = true;
            } else {
                counter++;
            }
        }
    }

    public void read(int id) throws IOError, Error{
        var file = File.new_for_path(subDir + "/" + id.to_string());
        if (!file.query_exists ()){
            throw new IOError.NOT_FOUND(_("Cannot load file: ") + id.to_string());
        } else {
            _fileId = id;
            Json.Parser parser = new Json.Parser ();
            parser.load_from_file (subDir + "/" + id.to_string());
            Json.Node node = parser.get_root ();
            Json.Object obj = node.get_object ();
            name = obj.get_string_member ("name");
            description = obj.get_string_member ("description");
            Json.Object tmpObj = obj.get_object_member ("cycle");
            Interval tCycle = { 0, DAY };
            tCycle.qty = (int)tmpObj.get_int_member ("qty");
            var cycleType = tmpObj.get_string_member ("type");
            switch (cycleType) {
                case "Day":
                    tCycle.type = DAY;
                    break;
                case "Week":
                    tCycle.type = WEEK;
                    break;
                case "Month":
                    tCycle.type = MONTH;
                    break;
                case "Year":
                    tCycle.type = YEAR;
                    break;
                default:
                    throw new IOError.INVALID_DATA("Invalid interval type");
            }
            _cycle = tCycle;
            tmpObj = obj.get_object_member ("remindMe");
            remindMe.qty = (int)tmpObj.get_int_member ("qty");
            var remindMeType = tmpObj.get_string_member ("type");
            switch (remindMeType) {
                case "Day":
                    remindMe.type = DAY;
                    break;
                case "Week":
                    remindMe.type = WEEK;
                    break;
                case "Month":
                    remindMe.type = MONTH;
                    break;
                case "Year":
                    remindMe.type = YEAR;
                    break;
                default:
                    throw new IOError.INVALID_DATA("Invalid interval type");
            }
            tmpObj = obj.get_object_member ("firstBillDate");
            firstBillDate = new DateTime.local((int)tmpObj.get_int_member("year"), (int)tmpObj.get_int_member("month"), (int)tmpObj.get_int_member("day"), 0, 0, 0);
            currency = obj.get_string_member ("currency");
            amount = (int)obj.get_int_member ("amount");
        }
    }

    public static Gee.ArrayList<int> getFileList(){
        subDir = Environment.get_user_data_dir() + "/com.github.jeremyvaartjes.subminder";
        var list = new Gee.ArrayList<int>();
        try {
            Dir dir = Dir.open (subDir, 0);
            string? name = null;

            while ((name = dir.read_name ()) != null) {
                string path = Path.build_filename (subDir, name);

                if (FileUtils.test (path, FileTest.IS_REGULAR)) {
                    list.add(int.parse(name));
                }
            }
        } catch (FileError err) {
            stderr.printf (err.message);
        }

        return list;
    }

    public bool remove() {
        var dir = File.new_for_path(subDir);
        if (!dir.query_exists ()){
            return false;
        }else{
            var file = File.new_for_path(subDir + "/" + fileId.to_string());
            if (!file.query_exists ()){
                return false;
            }else{
                try{
                    file.delete();
                } catch (Error e) {
                    print ("Error: %s\n", e.message);
                    return false;
                }
            }
        }
        return true;
    }

    private void updateNextDates(){
        if(_cycle.qty != 0){
            nextBillDate = _firstBillDate;
            var done = false;
            while(!done){
                switch (_cycle.type) {
                    case DAY:
                        nextBillDate = nextBillDate.add_days(_cycle.qty);
                        if(nextBillDate.difference(today()) >= 0){
                            done = true;
                        }
                        break;
                    case WEEK:
                        nextBillDate = nextBillDate.add_weeks(_cycle.qty);
                        if(nextBillDate.difference(today()) >= 0){
                            done = true;
                        }
                        break;
                    case MONTH:
                        nextBillDate = nextBillDate.add_months(_cycle.qty);
                        if(nextBillDate.difference(today()) >= 0){
                            done = true;
                        }
                        break;
                    case YEAR:
                        nextBillDate = nextBillDate.add_years(_cycle.qty);
                        if(nextBillDate.difference(today()) >= 0){
                            done = true;
                        }
                        break;
                }
            }

            switch (remindMe.type) {
                case DAY:
                    nextNotification = nextBillDate.add_days(-remindMe.qty);
                    break;
                case WEEK:
                    nextNotification = nextBillDate.add_weeks(-remindMe.qty);
                    break;
                case MONTH:
                    nextNotification = nextBillDate.add_months(-remindMe.qty);
                    break;
                case YEAR:
                    nextNotification = nextBillDate.add_years(-remindMe.qty);
                    break;
            }

            if(nextNotification.difference(today()) < 0){
                switch (_cycle.type) {
                    case DAY:
                        nextNotification = nextNotification.add_days(_cycle.qty);
                        break;
                    case WEEK:
                        nextNotification = nextNotification.add_weeks(_cycle.qty);
                        break;
                    case MONTH:
                        nextNotification = nextNotification.add_months(_cycle.qty);
                        break;
                    case YEAR:
                        nextNotification = nextNotification.add_years(_cycle.qty);
                        break;
                }
            }

            //stdout.printf("%s: %s -> %s(%s)\n", name, _firstBillDate.to_string(), nextBillDate.to_string(), nextNotification.to_string());
        }
    }
}

public DateTime today(){
    var now = new DateTime.now_local();
    var dayOnly = new DateTime.local(now.get_year(), now.get_month(), now.get_day_of_month(), 0, 0, 0);
    return dayOnly;
}