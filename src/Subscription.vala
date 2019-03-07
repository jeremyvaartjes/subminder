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
    private DateTime _nextBillDate;
    private DateTime _previousBillDate;
    private Interval _cycle;

    public string name;
    public string description;
    public DateTime firstBillDate;
    public DateTime nextBillDate { get{ return _nextBillDate; } }
    public Interval cycle{
        get{
            return _cycle;
        }
        set {
            _cycle = value;
            switch (_cycle.type) {
                case DAY:
                    _nextBillDate = _previousBillDate.add_days(_cycle.qty);
                    break;
                case WEEK:
                    _nextBillDate = _previousBillDate.add_weeks(_cycle.qty);
                    break;
                case MONTH:
                    _nextBillDate = _previousBillDate.add_months(_cycle.qty);
                    break;
                case YEAR:
                    _nextBillDate = _previousBillDate.add_years(_cycle.qty);
                    break;
            }
        }
    }
    public DateTime previousBillDate{
        get{
            return _previousBillDate;
        }
        set {
            _previousBillDate = value;
            switch (_cycle.type) {
                case DAY:
                    _nextBillDate = value.add_days(_cycle.qty);
                    break;
                case WEEK:
                    _nextBillDate = value.add_weeks(_cycle.qty);
                    break;
                case MONTH:
                    _nextBillDate = value.add_months(_cycle.qty);
                    break;
                case YEAR:
                    _nextBillDate = value.add_years(_cycle.qty);
                    break;
            }
        }
    }
    
    public Interval remindMe;
    public string currency;
    public int amount;
    public int fileId { get{ return _fileId; } }
    private static string subDir = "";

    public Subscription (){
        subDir = Environment.get_user_data_dir() + "/com.github.jeremyvaartjes.subminder";
        name = "";
        description = "";
        firstBillDate = new DateTime.now_local ();
        _nextBillDate = new DateTime.now_local ();
        previousBillDate = new DateTime.now_local ();
        cycle = { 1, IntervalType.DAY };
        remindMe = { 0, IntervalType.DAY };
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
        builder.set_member_name ("previousBillDate");
        builder.begin_object ();
        builder.set_member_name ("year");
        builder.add_int_value (previousBillDate.get_year());
        builder.set_member_name ("month");
        builder.add_int_value (previousBillDate.get_month());
        builder.set_member_name ("day");
        builder.add_int_value (previousBillDate.get_day_of_month());
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
            Json.Object tmpObj = obj.get_object_member ("firstBillDate");
            firstBillDate = new DateTime.local((int)tmpObj.get_int_member("year"), (int)tmpObj.get_int_member("month"), (int)tmpObj.get_int_member("day"), 0, 0, 0);
            tmpObj = obj.get_object_member ("previousBillDate");
            previousBillDate = new DateTime.local((int)tmpObj.get_int_member("year"), (int)tmpObj.get_int_member("month"), (int)tmpObj.get_int_member("day"), 0, 0, 0);
            tmpObj = obj.get_object_member ("cycle");
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
            cycle = tCycle;
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

    /*private string _name;
    private int _id;
    private string _url;
    private string _output;
    private string _requestType;
    private string _data;
    private string _contentType;
    private uint _testStatus;
    private bool _inProgress;
    private double _loadTime;
    private Gee.TreeMap<string,string> _headers;

    public string name {
        get { return _name; }
        set {
            var file = File.new_for_path(Environment.get_user_data_dir() + "/com.github.jeremyvaartjes.ping/tests/" + _id.to_string());
            if (file.query_exists ()){
                _name = value;
                this.outputToFile();
            }
        }
    }

    public string url {
        get { return _url; }
        set {
            var file = File.new_for_path(Environment.get_user_data_dir() + "/com.github.jeremyvaartjes.ping/tests/" + _id.to_string());
            if (file.query_exists ()){
                _url = value;
                this.outputToFile();
            }
        }
    }

    public string requestType {
        get { return _requestType; }
        set {
            var file = File.new_for_path(Environment.get_user_data_dir() + "/com.github.jeremyvaartjes.ping/tests/" + _id.to_string());
            if (file.query_exists ()){
                _requestType = value;
                this.outputToFile();
            }
        }
    }

    public string data {
        get { return _data; }
        set {
            var file = File.new_for_path(Environment.get_user_data_dir() + "/com.github.jeremyvaartjes.ping/tests/" + _id.to_string());
            if (file.query_exists ()){
                _data = value;
                this.outputToFile();
            }
        }
    }

    public string contentType {
        get { return _contentType; }
        set {
            var file = File.new_for_path(Environment.get_user_data_dir() + "/com.github.jeremyvaartjes.ping/tests/" + _id.to_string());
            if (file.query_exists ()){
                _contentType = value;
                this.outputToFile();
            }
        }
    }

    public int id { get { return _id; } }
    public string output { get { return _output; } set { _output = value; } }
    public uint testStatus { get { return _testStatus; } set { _testStatus = value; } }
    public bool inProgress { get { return _inProgress; } set { _inProgress = value; } }
    public double loadTime { get { return _loadTime; } set { _loadTime = value; } }
    public Gee.TreeMap<string,string> headers { get { return _headers; } set { _headers = value; } }

    public PingTest () throws Error{
        var counter = 1;
        var done = false;
        while(!done){
            var file = File.new_for_path(Environment.get_user_data_dir() + "/com.github.jeremyvaartjes.ping/tests/" + counter.to_string());
            if (!file.query_exists ()){
                var dir = File.new_for_path(Environment.get_user_data_dir() + "/com.github.jeremyvaartjes.ping/tests");
                if (!dir.query_exists ()){
                    dir.make_directory_with_parents ();
                }

                file.create(FileCreateFlags.NONE);

                _id = counter;
                _name = _("New API Test");
                _url = "";
                _output = "";
                _testStatus = 0;
                _requestType = "GET";
                _data = "";
                _contentType = "application/json";
                _inProgress = false;
                _loadTime = 0;
                this.outputToFile();
                done = true;
            } else {
                counter++;
            }
        }
    }

    public PingTest.load(int id) throws IOError {
        var file = File.new_for_path(Environment.get_user_data_dir() + "/com.github.jeremyvaartjes.ping/tests/" + id.to_string());
        if (!file.query_exists ()){
            throw new IOError.NOT_FOUND(_("Cannot load file: ") + id.to_string());
        } else {
            _id = id;
            Json.Parser parser = new Json.Parser ();
            parser.load_from_file (Environment.get_user_data_dir() + "/com.github.jeremyvaartjes.ping/tests/" + id.to_string());
            Json.Node node = parser.get_root ();
            Json.Object obj = node.get_object ();
            _name = obj.get_string_member ("name");
            _url = obj.get_string_member ("url");
            _requestType = obj.get_string_member ("requestType");
            _data = obj.get_string_member ("data");
            _contentType = obj.get_string_member ("contentType");
            _output = "";
            _testStatus = 0;
            _inProgress = false;
            _loadTime = 0;
        }
    }

    public bool remove() {
        var dir = File.new_for_path(Environment.get_user_data_dir() + "/com.github.jeremyvaartjes.ping/tests");
        if (!dir.query_exists ()){
            return false;
        }else{
            var file = File.new_for_path(Environment.get_user_data_dir() + "/com.github.jeremyvaartjes.ping/tests/" + _id.to_string());
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

    public static Gee.ArrayList<int> getListOfTests(){
        var list = new Gee.ArrayList<int>();
        try {
            string directory = Environment.get_user_data_dir() + "/com.github.jeremyvaartjes.ping/tests";
            Dir dir = Dir.open (directory, 0);
            string? name = null;

            while ((name = dir.read_name ()) != null) {
                string path = Path.build_filename (directory, name);

                if (FileUtils.test (path, FileTest.IS_REGULAR)) {
                    list.add(int.parse(name));
                }
            }
        } catch (FileError err) {
            stderr.printf (err.message);
        }

        return list;
    }

    private void outputToFile() throws Error{
        Json.Builder builder = new Json.Builder ();

        builder.begin_object ();
        builder.set_member_name ("name");
        builder.add_string_value (_name);
        builder.set_member_name ("url");
        builder.add_string_value (_url);
        builder.set_member_name ("requestType");
        builder.add_string_value (_requestType);
        builder.set_member_name ("data");
        builder.add_string_value (_data);
        builder.set_member_name ("contentType");
        builder.add_string_value (_contentType);
        builder.end_object ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);
        generator.to_file(Environment.get_user_data_dir() + "/com.github.jeremyvaartjes.ping/tests/" + _id.to_string());
    }*/
}