
%% Analyse of LGI1 patients seizures


addpath C:\Users\paul.baudin\Documents\MATLAB\fieldtrip;
addpath (genpath('C:\Users\paul.baudin\Documents\MATLAB\epilepsy'));
addpath C:\Users\paul.baudin\Documents\MATLAB\DTX;
addpath C:\Users\paul.baudin\Documents\MATLAB\MatlabImportExport_v6.0.0;
ft_defaults



feature('DefaultCharacterSet', 'CP1252') % To fix bug for weird character problems in reading neuralynx


config = dtx_setparams_patientsLGI1([]);
cfg=config{1}; %provisoire, a supprimer

for ipatient = 1
    
    %% Get LFP data
    % read muse markers
    [MuseStruct_micro, MuseStruct_macro]    = readMuseMarkers_parts(config{ipatient}, false);
    
    % align Muse markers according to peaks and detect whether they contain artefacts
    [MuseStruct_micro, MuseStruct_macro]    = alignMuseMarkers(config{ipatient},MuseStruct_micro, MuseStruct_macro, false);
    
    %jusque l�, extraire markers et les aligner commun quelle que soit
    %l'�lectrode � analyser
    
    % read LFP data : micro et macro coup�es comme d�finit dans le script et
    % dans setparams. Avec tous les canaux micro et macro nomm� dans cfg
    fprintf('***********************************************************\n');
    fprintf('***********************************************************\n');
    fprintf('** read, cut and and save LFP data for rat %d **\n',ipatient);
    fprintf('***********************************************************\n');
    fprintf('***********************************************************\n\n');
    
    [dat_macro] = readLFP_parts_macro(config{ipatient}, MuseStruct_macro, false, false);
    
    set(gcf, 'Renderer', 'Painters');

    set(0, 'defaultFigureRenderer', 'painters')
respectively

set(groot, 'defaultFigureRenderer', 'painters')

    cfg = [];
    cfg.channel = {'EMG*'};
    dat_EMG = ft_selectdata(cfg,dat_macro{1}{1});    
    
%     cfg = [];
%     cfg.channel = {'EEG'};
%     dat_EEG = ft_selectdata(cfg,dat_macro{1}{1});  
%     

    cfg = [];
    cfg.channel = {'EEG'};
    dat_EEG_avg = ft_timelockanalysis(cfg,dat_macro{1}{1});
    
    
%     
%     
%     fig = figure;
%     fig.Renderer = 'Painters'; % Else pdf is saved to bitmap
%     

    % baseline correction
    cfg = [];
    cfg.baseline = [-10 -5];
    dat_EEG_avg_bl = ft_timelockbaseline(cfg,dat_EEG_avg);

    figure
    cfg = [];
    cfg.layout = 'EEG1020';
    cfg.colorbar = 'yes';
    cfg.zlim = 'maxabs';
    ft_topoplotER(cfg,dat_EEG_avg_bl);
    
    figure;
    cfg = [];
    cfg.layout = 'EEG1020';
    ft_singleplotER(cfg,dat_EEG_avg);
    
    figure;
    cfg = [];
    cfg.layout = 'EEG1020';
    cfg.xlim = [-2 2];
    ft_multiplotER(cfg,dat_EEG_avg);
    
    % once you added trininfo for left-right

    figure;
    cfg = [];
    cfg.layout = 'EEG1020';
    cfg.xlim = [-2 2];
    ft_multiplotER(cfg,dat_EEG_avg);%dat_EEG_avg_left,dat_EEG_avg_right);
    
    figure;
    cfg = [];
    cfg.layout = 'EEG1020';
    cfg.colorbar = 'yes';
    cfg.zlim = [-100 100];%'maxabs';    
    cfg.xlim = [-2:0.25:2];
    ft_topoplotER(cfg,dat_EEG_avg);
    
    
    % movie!
    figure;
    cfg = [];
    cfg.layout = 'EEG1020';
    cfg.framespersec = 256; %5 frames per second
    cfg.samperframe = 1; 
    cfg.colorbar = 'yes';
    cfg.zlim = [-100 100];    
    cfg.xlim = [-3 10];
%     cfg.xlim = [-4:0.5:4];
    cfg.samperframe = 100;
    ft_movieplotER(cfg,dat_EEG_avg);
    
    
    
    
    fprintf('******************************\n');
    fprintf('******************************\n');
    fprintf('**** Plot data, for rat %d ****\n',ipatient);
    fprintf('******************************\n');
    fprintf('******************************\n\n');
    
    
    %% 
    % search EEG and EMG channels 
      for ichannel = 1 : length(dat_macro{1}{1}.label)
          if strcmp(dat_macro{1}{1}.label{ichannel},config{ipatient}.labels.macro{2})
              iEEG = [ichannel];
          end
          if strcmp(dat_macro{1}{1}.label{ichannel},config{ipatient}.labels.emg{1})
              iEMG = [ichannel];
          end
      end
    plot_SlowWave_emg(config{ipatient}, dat_macro{1}{1}, iEEG, iEMG);
    
    
 % plot slow wave time to see regularity 
 figure;
 hold
 for i=1:length(MuseStruct_macro{1, 1}{1, 1}.markers.SlowWave.synctime)
    t = (MuseStruct_macro{1, 1}{1, 1}.markers.SlowWave.synctime(i))/60;
    line([t,t],[-1,1],'color','k'); %si data d�cal�es
 end
ylim([-5 5]);
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for macro_id = 1 %EMG1+ %[config{ipatient}.LFP.electrodeToPlot(1), config{ipatient}.LFP.electrodeToPlot(2)]
        %% time frequency analysis
        for i_t_ftimwin = 40%[40, 80, 160]%[9, 20, 40]
            %foi_max=100;
            
            cfgtemp                         = [];
            cfgtemp.channel                 = macro_id;%'all'; %ichannel;
            cfgtemp.method                  = 'mtmconvol'; %relative change. 'mtmfft' : frequency content
            cfgtemp.output                  = 'pow';
            cfgtemp.taper                   = 'hanning';
            cfgtemp.pad                     = 'nextpow2';
            cfgtemp.keeptrials              = 'yes'; %return average
            cfgtemp.foi                     = 0:0.2:45;%80:0.2:125;
            cfgtemp.t_ftimwin               = i_t_ftimwin./cfgtemp.foi;
            %cfgtemp.t_ftimwin               = 20./cfgtemp.foi;
            %cfgtemp.t_ftimwin               = 40./cfgtemp.foi;
            %cfgtemp.t_ftimwin               = ones(size(cfgtemp.foi))*0.5;
            
            cfgtemp.toi                     = [-10:0.01:15];
            TFR_macro                    = ft_freqanalysis(cfgtemp,dat_macro{1}{1});
            
            TFR_macro_log = TFR_macro;
            TFR_macro_log.powspctrm = log(TFR_macro.powspctrm);
            
            % without baseline relchange
                        fig = figure;
                        subplot(2,1,1);
                        ft_singleplotTFR([], TFR_macro);
            
                        title(sprintf('%s%s : Frequency power over time',config{ipatient}.prefix,dat_macro{1}{1}.label{macro_id}),'Interpreter','none');
                        %xlim([-1, 1]);
                        %ylim([80 125]);
                        xlabel('Time from Slow Wave (s)');
                        ylabel('Frequency (Hz)');
            
                        subplot(2,1,2);
                        ft_singleplotTFR([], TFR_macro_log);
                        title(sprintf('%s%s : Frequency log power over time',config{ipatient}.prefix,dat_macro{1}{1}.label{macro_id}),'Interpreter','none');
                        %xlim([-5, 5]);
                        xlabel('Time from Slow Wave (s)');
                        ylabel('Frequency (Hz)');
%             
%             
            
%             
%             %ft_singleplotTFR([], TFR_macro_log);
%             %for foi_max = [25, 50]
%             foi_max=50;
%             %Plot
%             fig_title = sprintf('%s%s : Relative change from Baseline (-4s to -2s)',config{ipatient}.prefix,dat_macro{1}{1}.label{macro_id});
%             fig = figure;
%             subplot(2,1,1);
%             cfgtemp               = [];
%             %                 cfgtemp.channel         = macro_id;
%             cfgtemp.baseline        = [-4, -2];
%             cfgtemp.baselinetype    = 'relchange';
%             %cfgtemp.colorbar        = 'no';
%             cfgtemp.colorbar        = 'yes';
%             cfgtemp.zlim            = 'maxabs';
%             cfgtemp.xlim            = [-5 25];
%             cfgtemp.ylim            = [0 foi_max];
%             cfgtemp.title           = fig_title;
%             cfgtemp.parameter       = 'powspctrm';
%             cfgtemp.colormap        = parula(5000);
%             cfgtemp.renderer        = 'painters';
%             ft_singleplotTFR(cfgtemp, TFR_macro);
%             
%             %                 if adapt_colormap==1
%             %colormap_axis = caxis;
%             %caxis([0,colormap_axis(2)]);
%             %                 end
%             %              colormap_axis = caxis;
%             %              caxis([colormap_axis(1)/1.8,colormap_axis(2)*1.5]);
%             %              xlabel('Time from Slow Wave (s)');
%             %              ylabel('Frequency (Hz)');
%             %              c=colorbar;
%             %              c.Label.String = 'Power relative change';
%             %
%             subplot(2,1,2);
%             fig2_title = sprintf('%s%s : Relative change (log power) from Baseline (-4s to -2s)',config{ipatient}.prefix,dat_macro{1}{1}.label{macro_id});
%             cfgtemp               = [];
%             %cfgtemp.channel         = macro_id;
%             cfgtemp.baseline        = [-4, -2];
%             cfgtemp.baselinetype    = 'relchange';
%             %cfgtemp.colorbar        = 'no';
%             cfgtemp.colorbar        = 'yes';
%             cfgtemp.zlim            = 'maxabs';
%             cfgtemp.xlim            = [-5 25];
%             cfgtemp.ylim            = [0 foi_max];
%             cfgtemp.title           = fig2_title;
%             cfgtemp.parameter       = 'powspctrm';
%             cfgtemp.colormap        = parula(5000);
%             cfgtemp.renderer        = 'painters';
%             ft_singleplotTFR(cfgtemp,TFR_macro_log);
%             %
%             %                 if adapt_colormap==1
%             %                     colormap_axis = caxis;
%             %caxis([-log10(colormap_axis(2)),log10(colormap_axis(2))]);
%             %                 end
%             % xlim([-5, 5]);
%             %              xlabel('Time from Slow Wave (s)');
%             %              ylabel('Frequency (Hz)');
%             %              c=colorbar;
%             %              c.Label.String = 'Log of power relative change';
%             
%             % print to file
%             fig.Renderer = 'Painters'; % Else pdf is saved to bitmap
%             set(fig,'PaperOrientation','landscape');
%             set(fig,'PaperUnits','normalized');
%             set(fig,'PaperPosition', [0 0 1 1]);
%             print(fig, '-dpdf', fullfile(config{ipatient}.imagesavedir,'tfr_seizures',[config{ipatient}.prefix,dat_macro{1}{1}.label{macro_id}, '_Avg_TFR_seizures_',num2str(foi_max),'Hz_',num2str(i_t_ftimwin)]),'-r600');
%             print(fig, '-dpng', fullfile(config{ipatient}.imagesavedir,'tfr_seizures',[config{ipatient}.prefix,dat_macro{1}{1}.label{macro_id}, '_Avg_TFR_seizures_',num2str(foi_max),'Hz_',num2str(i_t_ftimwin)]),'-r600');
%             close all
%             
            clear TFR_macro TFR_macro_log
        end
        
        
    end
    
end






    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %% timecourse 
    %for macro_id = [config{ipatient}.LFP.electrodeToPlot(1), config{ipatient}.LFP.electrodeToPlot(2)]
    for macro_id = config{ipatient}.LFP.electrodeToPlot(1)
        
        %search electrode index in the dat_macro (not the same in all
        %patients)
        
        for ichannel = 1 : length(dat_macro{1}{1}.label)
            if strfind(dat_macro{1}{1}.label{ichannel},config{ipatient}.labels.macro{macro_id})
                channelindx = [ichannel];
            end
        end
        
        macro_id = channelindx;
        
        %% plot all trials of one macro
        for abscisse_max = 2
            for i_size_amplitude = 1
                for i_amplification = 1
                    %for i_size_amplitude = 5:7
                    fig             = figure;
                    hold;
                    fig.Renderer    = 'Painters'; % Else pdf is saved to bitmap
                    h               = 10000/(10*(i_size_amplitude));
                    n               = size(dat_macro{1}{1}.trial,2);
                    for itrial = 1 : size(dat_macro{1}{1}.trial,2)
                        plot(dat_macro{1}{1}.time{itrial},dat_macro{1}{1}.trial{itrial}(macro_id,:)*i_amplification + n*h - itrial*h,'k'); %first on top
                    end

                    xlabel('Time from SlowWave (s)');
                    ylabel('Number of seizures');
                    title(sprintf('%s : Aligned data from %s',config{ipatient}.prefix(1,1:end-1), dat_macro{1}{1}.label{macro_id}),'Interpreter','none');
                    set(gca, 'YTickLabel', '');
                    tick = h;
                    yticks(0 : tick*10 : n*h);
                    yticklabels(n : -10 : 0);
                    set(gca,'TickDir','out');
                    axis tight
                    if abscisse_max == 2
                        xlim([-2, 2]);
                    else
                        xlim([-5, abscisse_max]);
                    end

%                     % print to file
%                     set(fig,'PaperOrientation','landscape');
%                     set(fig,'PaperUnits','normalized');
%                     set(fig,'PaperPosition', [0 0 1 1]);
%                     set(fig,'Renderer','Painters');
%                     print(fig, '-dpdf', fullfile(config{ipatient}.imagesavedir,'timecourse_seizures',[config{ipatient}.prefix,dat_macro{1}{1}.label{macro_id},'_Timecourse_seizures_',...
%                         num2str(abscisse_max),'s_Sizex',num2str(i_amplification),'_',num2str(i_size_amplitude)]),'-r600');
%                     print(fig, '-dpng', fullfile(config{ipatient}.imagesavedir,'timecourse_seizures',[config{ipatient}.prefix,dat_macro{1}{1}.label{macro_id},'_Timecourse_seizures_',...
%                         num2str(abscisse_max),'s_Sizex',num2str(i_amplification),'_',num2str(i_size_amplitude)]),'-r600');
%                     close all
                end
            end %i_size_amplitude
        end %abscisse_max
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% average over trials for plotting of all channels
    for abscisse_max = 15%[2, 5, 10]

        cfgtemp                 = [];
        cfgtemp.vartrllength    = 2;
        %dat_micro_rptavg        = ft_timelockanalysis(cfgtemp,dat_micro{1}{1});
        dat_macro_rptavg        = ft_timelockanalysis(cfgtemp,dat_macro{1}{1});

        fig=figure;
        hold;
        h=200;
        for i = 1 : size(dat_macro_rptavg.label,1)
            %subplot(size(dat_macro_rptavg.label,1),1,size(dat_macro_rptavg.label,1)-i+1);
            %         plot(dat_micro_rptavg.time,dat_micro_rptavg.avg)
            plot(dat_macro_rptavg.time,dat_macro_rptavg.avg(i,:)+h*i,'color','black');

        end
        title(sprintf('Average of all SlowWaves of %s',config{ipatient}.prefix(1:end-1)),'Interpreter','none');
        axis tight;
        xlabel('Time (s)');
        ylabel('Channel name');
        tick = h;
        yticks(0 : tick : length(dat_macro_rptavg.label)*h);
        set(gca, 'YTickLabel',[dat_macro_rptavg.label(end)', dat_macro_rptavg.label(1:end-1)']); %why Y axis not in the good order
        set(gca,'TickDir','out');
%         if abscisse_max == 2
%             xlim([-2, 2]);
%         else
%             xlim([-5, abscisse_max]);
%         end
%         line ([abscisse_max-0.5,abscisse_max-0.5],[h*i-2500,h*i-500],'color','r','LineWidth',2);
%         text(abscisse_max-0.45, h*i-1400,'2mV','FontSize',15);


%         % print to file
%         fig.Renderer = 'Painters'; % Else pdf is saved to bitmap
%         set(fig,'PaperOrientation','landscape');
%         set(fig,'PaperUnits','normalized');
%         set(fig,'PaperPosition', [0 0 1 1]);
%         print(fig, '-dpdf', fullfile(config{ipatient}.imagesavedir,'average_SlowWave',[config{ipatient}.prefix,'_Avg_SlowWaves_MACRO_',num2str(abscisse_max),'s']),'-r600');
%         print(fig, '-dpng', fullfile(config{ipatient}.imagesavedir,'average_SlowWave',[config{ipatient}.prefix,'_Avg_SlowWaves_MACRO_',num2str(abscisse_max),'s']),'-r600');
% 
%         close all


    end

end

%% figure totale patients