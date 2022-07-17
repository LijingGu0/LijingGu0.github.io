% % %m_Step_2_Extract_P2_N2_withinsubject_PCA
%%% To extract P2 and N2 from single-trial EEG of an individual for all remained trials


%%Uses the outputs from:m_Step_1_Filter_data_by_wavelet_filter.m



%%% In order to run this code, please install EEGLAB toolboxes. It can be downloaded from http://sccn.ucsd.edu/eeglab/
%%% This code was written by GuangHui Zhang, July 2022, JYU
%%% Faculty of Information Technology, University of Jyv�skyl�
%%% Address: Seminaarinkatu 15,PO Box 35, FI-40014 University of Jyv�skyl�,Jyv�skyl�, FINLAND
%%% E-mails: zhang.guanghui@foxmail.com


%%% When using this code, please cite the following articles:
%%% 1. Fengyu Cong, Yixiang Huang, Igor Kalyakin, Hong Li, Tiina Huttunen-Scott, Heikki Lyytinen, Tapani Ristaniemi,
%%% Frequency Response based Wavelet Decomposition to Extract Children's Mismatch Negativity Elicited by Uninterrupted Sound,
%%% Journal of Medical and Biological Engineering, 2012, 32(3): 205-214, DOI: 10.5405/jmbe.908
%%% 2. Guanghui Zhang, Xueyan Li, and Fengyu Cong. Objective Extraction of Evoked Event-related Oscillation from Time-frequency Representation of Event-related Potentials.
%%% Neural Plasticity. DOI:10.1155/2020/8841354
%%% 3. Lu, Y., Luo, Y., Lei, Y., Jaquess, K. J., Zhou, C., & Li, H. (2016). Decomposing valence intensity effects in disgusting and fearful stimuli: an event-related potential study.
%%% Social neuroscience, 11(6), 618-626. doi:https://doi.org/10.1080/17470919.2015.1120238





clear
clc
close all

%%
tic


%%-------------------------------------Basic Settings----------------------
%Location of the main study directory
%This method of specifying the study directory only works if you run the script;
%for running individual lines of code, replace the study directory with the path on your computer, e.g.: DIR = \Users\Lu_Emotional_ERP_Experiment
Subject_file_Path = fileparts(fileparts(mfilename('fullpath')));


%Location of the folder that contains this script and any associated processing files
%This method of specifying the current file path only works if you run the script;
%For running individual lines of code, replace the current file path with the path on your computer, e.g.: DIR = \Users\Lu_Emotional_ERP_Experiment\Codes_for_EEG_ERP_Processing
Current_File_Path = fileparts(mfilename('fullpath'));

%List of subjects to process, based on the name of the folder that contains that subject's data
Subject_Name_p2 = [1:2,4,7:10,14:16,18:21,24:26];%%Orders for all participants that used to extract P2.

Subject_Name_n2 = [1:4,7:10,13,14:16,18:22,24:26];%%Orders for all participants that used to extract N2.

timeStart = -200;%%Left interval for each trial
timeEnd = 900;%%Right interval for each trial
fs = 500;%%Sampling rate
load chanlocs;
pathName = ['Factors_three_PCA_methods_increased_trials and all trials',filesep];
Factor_P2 = importdata([pathName,'P2_individual_PCA_factor_order_all_trials.mat']);
Factor_N2 = importdata([pathName,'N2_individual_PCA_factor_order_all_trials.mat']);

% List of stimulus for each subject to process separately, based on the name of the sub-folder that contains that subject's data
Sti_names = {'MD','MF','ED','EF','DN','DF'};%%Names for stimuli

Flag_plot_component = 2;%% Whether plot temporal and spatial components or not(1.Yes; 2.No).


for Numofcomponent = 1:2% 1.P2; 2.N2
    if Numofcomponent==1
        subName = Subject_Name_p2;
        Selectedcomponents_K = Factor_P2;
    else
        subName = Subject_Name_n2;
        Selectedcomponents_K = Factor_N2;
    end
    M = [];
    for Numofsub = 1:length(subName)
        route1 = char(strcat('2_within-subject PCA for all trials',filesep,num2str(subName(Numofsub)),filesep));
        mkdir(route1);
        pn = char(strcat('1_wavelet_filter',filesep));
        fn = char(strcat(num2str(subName(Numofsub)),'.mat'));
        D = [];
        D = importdata([pn,fn]);
        sti_trial_label =[];
        count1  =0;
        count = 0;
        X = [];
        stiNum = length(fieldnames(D));
        fieldNames = fieldnames(D);
        for Numofsti = 1:stiNum
            count1= count1+1;
            data = [];
            trialNum = [];
            data = getfield(D,fieldNames{Numofsti});
            [chanNum,samPoints,trialNum] = size(data);
            sti_trial_label = [sti_trial_label;count1*ones(trialNum,1)];
            for Numoftrial = 1:trialNum
                count = count +1;
                X(:,:,count)  = squeeze(data(:,:,Numoftrial));
            end
        end
        
        [NumChans,NumSamps,NumSubs] = size(X);
        X = permute(X,[2 1 3]);
        %% grouping data into a matrix
        X= reshape(X,NumSamps,NumChans*NumSubs);
        timeIndex = linspace(timeStart,timeEnd,NumSamps);
        
        %%  PCA
        [coef,score,lambda] = pca(X');
        ratio = f_explainedVariance(lambda);
        %%% Defined the explained number and determine the number of the remained components
        
        R = 40;%%Number of sources
        for is = 1:length(lambda)
            ratio_sigle(is) = 100*lambda(is)./sum(lambda);
        end
        ratio_sigle_keep = ratio_sigle(1:R);
        %% rotation
        Y = [];
        T = [];
        V = coef(:,1:R);
        Z = score(:,1:R);
        %% rotation for blind source separation
        [translated_V,W] = rotatefactors(V, 'Method','promax','power',3,'Maxit',500);
        B = inv(W');
        Y = Z*W; %%% spatial components
        T = V*B;  %%% temporal components
        peakValue = [];
        peakTime = [];
        peak_T = [];
        [peakValue,peakTime] = max(abs(T));
        timePstart = round((0-timeStart)/(1000/fs))+1;
        for r = 1 :R
            temp = T(:,r);
            T (:,r) =  temp - mean(temp(1:timePstart));
            peak_T(r) = round((peakTime(r)-1)*(1000/fs)) + timeStart;
        end
        %%
        topo  =[];
        topo = reshape(Y',R,NumChans,NumSubs);
        topo_similarity_AV =[];
        topo_av = [];
        RHO = [];
        topo_similarity_AV =[];
        count =0;
        %%
        for Numofsti =1:6
            idx1 = find(sti_trial_label == Numofsti);
            topo_av(:,:,Numofsti) =  squeeze(mean(topo(:,:,idx1),3));
            for k = 1:R
                temp1 = corr(squeeze(topo(k,:,idx1)));
                topo_similarity{:,:,k,Numofsti} = temp1;
                RHO(k,Numofsti) = mean(temp1(:));
            end
        end
        rho = mean(RHO,2);
        [rho_ranked, idx] = sort(rho,'descend');
        %% Explained variance of each component of keep componets and Correlation Coefficient between spatial components
        if Flag_plot_component == 1
            %%  plot results of temporal components and spatial components
            rowNum = 3;
            columnNum = 6;
            selectedComponentNumbers =[];
            count_select = 0;
            
            count_rr = ceil(rowNum/2)*columnNum+ 1;
            for kk = 1:R
                k = idx(kk);
                topo_k = squeeze(topo_av(k,:,:));
                mV = max(abs(topo_k(:)));
                figure(k)
                set(gcf,'outerposition',get(0,'screensize'));
                subplot(rowNum,columnNum,[1:columnNum],'align')
                set(gca,'fontsize',14)
                plot(timeIndex,T(:,k),'k','linewidth',3)
                xlim([timeStart timeEnd])
                grid on
                xlabel('Time/ms')
                ylabel('Magnitude')
                title(['Comp #',int2str(k),'(Explained variance =',num2str(roundn(ratio_sigle_keep(k),-2)),'%, Peak Time = ',num2str(peak_T(k)),'ms)']);
                set(gca,'ydir','reverse');
                count = 0;
                for groupNum = 1:6
                    count = count +1;
                    subplot(rowNum,columnNum,columnNum + count,'align')
                    set(gca,'fontsize',14)
                    topoplot(squeeze(topo_av(k,:,groupNum)),chanlocs,'maplimits',[-mV,mV]);
                    colorbar;
                    if groupNum ==1
                        tN = strcat(Sti_names{groupNum});
                    else
                        tN = Sti_names{groupNum};
                    end
                    title(tN,'fontsize',14);
                    set(gca,'clim',[-mV mV])
                    subplot(rowNum,columnNum,ceil(rowNum/2)*columnNum+count,'align')
                    set(gca,'fontsize',14)
                    imagesc(squeeze(topo_similarity{:,:,k,groupNum}))
                    set(gca,'clim',[-1 1])
                    colorbar;
                    if groupNum ==1
                        tN = strcat('Corr#',num2str(roundn(rho_ranked(kk),-2)),32,Sti_names{groupNum});
                    else
                        tN = Sti_names{groupNum};
                    end
                    title(tN,'fontsize',14);
                    if ceil(rowNum/2)*columnNum +count == count_rr
                        xlabel('Subject #')
                        ylabel('Subject #')
                    end
                    
                end
                figureName = char(strcat('Component_',num2str(k)));
                set(figure(k),'paperunits','inches','paperposition',[0,0,16,9]);
                saveas(figure(k),[route1 figureName],'png');
                saveas(figure(k),[route1 figureName],'fig');
            end
            clear peak_T;
            clear rho_ranked;
        end
        
        if Flag_plot_component == 1
            msgbox(['If you want to reset orders of selected factors for sub#',num2str(subName(Numofsub)),',Please press any key!!!'])
            pause;
            prompt = {'Reset the orders of the factor of interest:'};
            dlg_title = 'Input';
            num_lines = 1;
            def = {Selectedcomponents_K{Numofsub}};
            answer = inputdlg(prompt,dlg_title,num_lines,def);
            selectedComponentNumbers = str2num(answer{1});
        else
            selectedComponentNumbers = Selectedcomponents_K{Numofsub};%% the orders of  selected components associated with N2
        end
        
        
        
        close all
        E = [];
        E = T(:,selectedComponentNumbers)*Y(:,selectedComponentNumbers)';
        temp = reshape(E,NumSamps,NumChans,[]);
        D = permute(temp,[2 1 3]);
        X = [];
        NumGroups = max(sti_trial_label);
        for groupNum = 1:NumGroups
            idx1 = [];
            idx1 = find(sti_trial_label == groupNum);
            X(:,:,groupNum) = squeeze(mean(D(:,:,idx1),3));
        end
        M(:,:,:,Numofsub) =  X;
        clear sti_trial_label;
        clear X;
    end
    if Numofcomponent==1
       save('PCA_withinsubject_P2','M','-v7.3'); 
    else
       save('PCA_withinsubject_N2','M','-v7.3');  
    end
end


uiwait(msgbox('The program ends'));
%%
toc