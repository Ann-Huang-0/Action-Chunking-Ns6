%addpath('/Users/ann/Desktop/CCN_Lab/BehavioralExperiment/Ns6_FinalVersion');
folder = 'experiment_manip_3block/data/';

subj = {'A11TREGDHSUSJW','A11YS0T8MV3Q7C','A19M1TGTL9HKHB','A1AKL5YH9NLD2V',...
'A1HFY6TQD2GBZA','A1PHDT66U6IK4Q','A1SHLWKA0UH1IS','A1SOFLJOEQB591','A1V1JNPU0KOA3X','A222GZB608T1B8',...
'A24LB89P1BPKKF','A2DVV59R1CQU6T','A2H1QUGX0SOUMH','A2I43BDUPAM00C','A2I4PRZ9IZMKON','A2P76QVLSGJR45',...
'A2T675UCHNTSSW','A2VNWJU49OOVFC','A2XQ3CFB5HT2ZQ','A2YGOORS5N9RW8','A30W987G9S6F0G',...
'A337Y4X67PY4QI','A34SUZWGLXIWM8','A36470UBRH28GO','A3DS5B06ZCD3E3','A3EC3OP6U52JYC',...
'A3FOKP72T5I4FR','A3HNEYFOIJWPH1','A3JAM040VWXHDO','A3L2XKXABNO0N5','A3LA5P3N3KI8U7',...
'A3P9TM5PRYBH90','A3PLWSCPFLCEGI','A3QSFE6GKO157S','A6HDSE80LQPR8','ADJ9I7ZBFYFH7',...
'AEWGY34WUIA32','AK3H5QRAROFGP','AKNYT1NTK2UFK','ANKDLLQHHM2OH'};


for s = 1:length(subj)
    % 1.rt  2.url  3.trial_type  4.trial_index  5.time_elapsed  % 6.internal_node_id
    % 11.stimulus  12.keypres  13.state  14.test_part
    % 15.correct_response  16.order_block  17.order_chunk
    % 18.order_frequency_discr  19.correct
    
    A = readtable(strcat(folder, subj{s}));
    A = table2cell(A);
    
    data(s).ID = subj{s};
    data(s).bonus = A{1704,19};
end

