package org.thalemine.web.service;

import java.util.List;

import org.thalemine.web.domain.PhenotypeVO;
import org.thalemine.web.domain.PublicationVO;
import org.thalemine.web.domain.StockGenotypeVO;

public interface PhenotypeService extends BusinessService {

	List<StockGenotypeVO> getGeneticContextObservedIn(String primaryIdentifier);

}
