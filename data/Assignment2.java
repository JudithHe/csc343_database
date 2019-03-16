import java.sql.*;
import java.util.List;

// If you are looking for Java data structures, these are highly useful.
// Remember that an important part of your mark is for doing as much in SQL (not Java) as you can.
// Solutions that use only or mostly Java will not receive a high mark.
import java.util.ArrayList;
//import java.util.Map;
//import java.util.HashMap;
//import java.util.Set;
//import java.util.HashSet;
public class Assignment2 extends JDBCSubmission {

    public Assignment2() throws ClassNotFoundException {

        Class.forName("org.postgresql.Driver");
    }

    @Override
    public boolean connectDB(String url, String username, String password) {
        // Implement this method!

        try {
            connection = DriverManager.getConnection(url,username,password);
            //set search_path to parlgov;
            if(connection!=null ||!connection.isClosed()){
                return true;
            }
        } catch (SQLException e) {
            return false;
        }
        return false;
        //return false;
    }

    @Override
    public boolean disconnectDB() {
        // Implement this method!
        if (connection != null) {
            try {
                connection.close();
            } catch (SQLException e) {return false;}
        }
        return true;
        //return false;
    }

    @Override
    public ElectionCabinetResult electionSequence(String countryName) {
        // Implement this method!
        //String queryStringElection = "SELECT e.id, e.previous_parliament_election_id, e.previous_ep_election_id, e.e_type" +
        String queryStringElection = "SELECT e1.e_id, e1.c_id FROM (SELECT e.id AS e_id, c.id AS c_id, e.e_date, c.start_date, e.country_id FROM parlgov.cabinet AS c LEFT JOIN parlgov.election AS e ON c.election_id = e.id) AS e1 LEFT JOIN parlgov.country AS c1 ON e1.country_id = c1.id WHERE c1.name = ? ORDER BY e1.e_date DESC, e1.start_date DESC;";
//        String queryStringCabinet = "SELECT c1.id" +
//                " FROM parlgov.cabinet AS c1 LEFT JOIN parlgov.country AS c2" +
//                " ON c2.id = c1.country_id" +
//                " WHERE c2.name = ?" +
//                " ORDER BY c1.start_date DESC;";
        PreparedStatement pStatement;
        ResultSet rs;
        ArrayList<Integer> electionList = new ArrayList<>();
        ArrayList<Integer> cabinetList = new ArrayList<>();
        ElectionCabinetResult result = new ElectionCabinetResult(electionList, cabinetList);
        try {
            pStatement = connection.prepareStatement(queryStringElection);
            pStatement.setString(1, countryName);
            rs = pStatement.executeQuery();

            while (rs.next()) {
                electionList.add(rs.getInt("e_id"));
                cabinetList.add(rs.getInt("c_id"));
            }

//            pStatement = connection.prepareStatement(queryStringCabinet);
//            pStatement.setString(1, countryName);
//            rs = pStatement.executeQuery();
//
//            while (rs.next()) {
//                cabinetList.add(rs.getInt("id"));
//            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return result;
    }

    @Override
    public List<Integer> findSimilarPoliticians(Integer politicianName, Float threshold) {
        // Implement this method!
        ArrayList<Integer> listOfPresidents = new ArrayList<>();
        String query1 = "SELECT id, comment, description FROM parlgov.politician_president WHERE id <> " + String.valueOf(politicianName);
        String query2 = "SELECT id, comment, description FROM parlgov.politician_president WHERE id = " + String.valueOf(politicianName);
        PreparedStatement stat1;
        PreparedStatement stat2;
        ResultSet set1;
        ResultSet set2;

        try {
            //presidents that are not the given politicianName
            stat1 = connection.prepareStatement(query1);
            set1 = stat1.executeQuery();

            //president that is the given politicianName
            stat2 = connection.prepareStatement(query2);
            set2 = stat2.executeQuery();

            set2.next();
            while (set1.next()) {
                float sim1 = (float) similarity(set1.getString("comment"), set2.getString("comment"));
                float sim2 = (float) similarity(set1.getString("description"), set2.getString("description"));
                if ((sim1 + sim2) > threshold) {
                    listOfPresidents.add(set1.getInt("id"));
                }

            }


        } catch (SQLException ex){
            ex.printStackTrace();
        }
        return listOfPresidents;
    }


    public static void main(String[] args) {
        // You can put testing code in here. It will not affect our autotester.
//        Assignment2 a = null;
//        try {
//            a = new Assignment2();
//            a.connectDB("jdbc:postgresql://localhost:5432/csc343h-<username>",
//                    "<username>",
//                    "");
//        } catch (ClassNotFoundException e) {
//            e.printStackTrace();
//        }
//        ElectionCabinetResult r;
//        //listOfPresidents = a.findSimilarPoliticians(113, (float) 0);
//        r = a.electionSequence("France");
//        System.out.print(r);
//        a.disconnectDB();

    }

}



