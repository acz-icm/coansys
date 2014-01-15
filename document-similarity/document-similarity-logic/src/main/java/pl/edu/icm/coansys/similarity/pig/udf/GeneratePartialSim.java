/*
 * This file is part of CoAnSys project.
 * Copyright (c) 2012-2013 ICM-UW
 * 
 * CoAnSys is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.

 * CoAnSys is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Affero General Public License for more details.
 * 
 * You should have received a copy of the GNU Affero General Public License
 * along with CoAnSys. If not, see <http://www.gnu.org/licenses/>.
 */

package pl.edu.icm.coansys.similarity.pig.udf;

/**
 *
 * @author pdendek
 */
import java.io.IOException;
import java.util.Arrays;

import org.apache.pig.EvalFunc;
import org.apache.pig.data.DataBag;
import org.apache.pig.data.DefaultDataBag;
import org.apache.pig.data.Tuple;
import org.apache.pig.data.TupleFactory;

public class GeneratePartialSim extends EvalFunc<DataBag> {
	
	public static class Pair implements Comparable<Pair>{
		String docId;
		Float tfidf;
		
		public Pair(String docId, Float tfidf){
			this.docId = docId;
			this.tfidf = tfidf;
		}

		@Override
		public int compareTo(Pair other) {
			return this.docId.compareTo(other.docId);
		}
		
		public boolean equals(Pair other){
			return this.docId.equals(other.docId) && tfidf.equals(other.tfidf);
		}
	}
	
	@Override
	public DataBag exec(Tuple input) throws IOException {
		String term = (String) input.get(0);
        DataBag docIdTermTfidf = (DataBag) input.get(1);
        
        int docsNum = (int)docIdTermTfidf.size();
        Pair[] docidTfidf = new Pair[docsNum];
        int idx = 0;
        for(Tuple t : docIdTermTfidf){
        	String docId = (String) t.get(0);
        	//String term = (String) t.get(1);
        	Float tfidf = (Float) t.get(2);
        	docidTfidf[idx] = new Pair(docId,tfidf); 
        	idx++;
        }
        Arrays.sort(docidTfidf);
        TupleFactory tf = TupleFactory.getInstance(); 
        DataBag db = new DefaultDataBag();
        
        for(int i=0;i<docsNum;i++){
        	for(int j=i+1;j<docsNum;j++){
        		Pair a = docidTfidf[i];
        		Pair b = docidTfidf[j];
        		Tuple t = tf.newTuple();
        		t.append(a.docId);
        		t.append(b.docId);
//        		t.append(term);
//        		t.append(a.tfidf);
//        		t.append(b.tfidf);
        		t.append(a.tfidf*b.tfidf);
        		db.add(t);
            }	
        }
		return db;
	}
}