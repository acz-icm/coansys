/*
 * (C) 2010-2012 ICM UW. All rights reserved.
 */
package pl.edu.icm.coansys.disambiguation.author.model.feature.extractor;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import org.apache.log4j.Logger;

import pl.edu.icm.coansys.disambiguation.author.jobs.DisambiguationJob_Toy;
import pl.edu.icm.coansys.disambiguation.author.model.feature.Extractor;
import pl.edu.icm.coansys.disambiguation.author.model.feature.indicator.DocumentBased;
import pl.edu.icm.coansys.importers.model.DocumentProtos.DocumentMetadata;

/**
 * 
 * @author pdendek
 *
 */
public class DocumentProto2KeyWordExtractor implements Extractor<DocumentMetadata>, DocumentBased{

	@SuppressWarnings("unused")
	private static Logger logger = Logger.getLogger(new DisambiguationJob_Toy().getClass());

	@Override
	public List<String> extract(DocumentMetadata input, String... auxil) {
		DocumentMetadata dm = (DocumentMetadata) input;
		ArrayList<String> ret = new ArrayList<String>();
		for(String kw : dm.getKeywordList()){
			ret.addAll(Arrays.asList(kw.split(" ")));
		}
		return ret;
	}
}
