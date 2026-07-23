
package path;
import java.sql.*;
import java.util.*;
import java.text.*;

import com.sun.rowset.*; 	
import javax.sql.rowset.*;
import java.util.Date;
import java.util.Map;
import java.util.Set;
import java.util.Vector;

public class pathBean {

    public pathBean() {
    }
    
    public Connection check() throws SQLException
   		{
		return util.DBConnectionManager.getConnectionFromPool();
		}
//////////////////////////----------------------------

//////////////////////////---------------------------
}