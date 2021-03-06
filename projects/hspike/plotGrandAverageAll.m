function plotGrandAverageAll(cfg)

set(groot,'defaultAxesTickLabelInterpreter','none');  

hyplabels   = ["REM",  "AWAKE", "PHASE_1", "PHASE_2", "PHASE_3"];

fname_out = fullfile(cfg{1}.datasavedir, 'GrandAverage.mat');

% organize all dat_unit_windowa in single struct array

iunit               = 1;
dat_unit_window     = table;
dat_unit_IED        = table;
dat_hyp             = table;

for ipatient = 1 : size(cfg, 2)
    
    SpikeTrials_timelocked  = readSpikeTrials_MuseMarkers(cfg{ipatient});
    SpikeDensity_timelocked = spikeTrialDensity(cfg{ipatient});
    cfg{ipatient}.postfix   = '-windowed';
    SpikeStats_windowed     = spikeTrialStats(cfg{ipatient});
    
    cfg{ipatient}.LFP.name  = string(fields(SpikeTrials_timelocked{1})');
    LFP                     = readLFP(cfg{ipatient});
    
    for ipart = 1 : size(SpikeTrials_timelocked, 2)
        
        % if no good units were found
        if isempty(SpikeDensity_timelocked{ipart})
            continue
        end
        
        for markername = string(fields(SpikeTrials_timelocked{ipart}))'
            
            % calculate max/min/RMS per trial
            cfgtemp         = [];
            cfgtemp.latency = [-0.2 0.5]; %cfg{ipatient}.align.latency
            dat_sel         = ft_selectdata(cfgtemp, LFP{ipart}.(markername));
            t               = reshape(cell2mat(dat_sel.trial), size(dat_sel.trial{1}, 1), size(dat_sel.trial{1}, 2), size(dat_sel.trial, 2));
            maxpeak         = max(t, [], 2);
            maxpeak         = max(maxpeak, [], 1);
            maxpeak         = squeeze(maxpeak); 
            minpeak         = max(t, [], 2);
            minpeak         = max(minpeak, [], 1);
            minpeak         = squeeze(minpeak);      
            clear dat_sel t 
            
            % concatinate data of time-locked spike activity
            dat_unit_IED_temp                  = SpikeTrials_timelocked{ipart}.(markername).trialinfo;
            dat_unit_IED_temp.ipatient         = repmat(ipatient, size(dat_unit_IED_temp, 1), 1);
            dat_unit_IED_temp.ipart            = repmat(ipart, size(dat_unit_IED_temp, 1), 1);
            dat_unit_IED_temp.markername       = repmat(markername, size(dat_unit_IED_temp, 1), 1);            
            dat_unit_IED_temp.Properties.VariableNames{'begsample'} = 'begsample_unit';
            dat_unit_IED_temp.Properties.VariableNames{'endsample'} = 'endsample_unit';
            dat_unit_IED_temp.Properties.VariableNames{'offset'} = 'offset_unit';
            dat_unit_IED_temp.Properties.VariableNames{'trialnr'} = 'trialnr_unit';
            dat_unit_IED_temp.Properties.VariableNames{'idir'} = 'idir_unit';
            dat_unit_IED_temp.Properties.VariableNames{'fileoffset'} = 'fileoffset_unit';
            dat_unit_IED_temp.Properties.VariableNames{'hyplabel'} = 'hyplabel_unit';
            
            % map trials according to directory & trialnr.
            for i = 1 : size(dat_unit_IED_temp, 1)
                indx_dir = strcmp(string(SpikeTrials_timelocked{ipart}.(markername).trialinfo.directory(i,:)), string(LFP{ipart}.(markername).trialinfo.directory));   
                indx_trl = SpikeTrials_timelocked{ipart}.(markername).trialinfo.trialnr_start(i) == LFP{ipart}.(markername).trialinfo.trialnr;
                if ~any(indx_trl & indx_dir)
                    fprintf('Cannot find correspondance between spike and LFP data for trial indx %d\n', i);
                    dat_unit_IED_temp.consistent(i) = false;
                else
                    dat_unit_IED_temp.maxpeak_lfp(i)    = maxpeak(indx_trl & indx_dir);
                    dat_unit_IED_temp.minpeak_lfp(i)    = minpeak(indx_trl & indx_dir);
                    dat_unit_IED_temp.hyplabel_lfp(i,:) = LFP{ipart}.(markername).trialinfo.hyplabel(indx_trl & indx_dir);
                    dat_unit_IED_temp.begsample_lfp(i)  = LFP{ipart}.(markername).trialinfo.begsample(indx_trl & indx_dir);
                    dat_unit_IED_temp.starttime_lfp(i)  = LFP{ipart}.(markername).trialinfo.starttime(indx_trl & indx_dir);
                    dat_unit_IED_temp.endtime_lfp(i)    = LFP{ipart}.(markername).trialinfo.endtime(indx_trl & indx_dir);
                    if dat_unit_IED_temp.hyplabel_unit(i,:) == dat_unit_IED_temp.hyplabel_lfp(i,:)
                        dat_unit_IED_temp.consistent(i)                        = true;
                    else
                        fprintf('Inconsitent hypnogram label spike and LFP data for trial indx %d\n', i);                    
                        dat_unit_IED_temp.consistent(i)                        = false;
                    end
                end
            end
            dat_unit_IED = vertcat(dat_unit_IED, dat_unit_IED_temp);
                        
            % loop over units for spikedensity per unit/trial
            for ilabel = 1 : size(SpikeDensity_timelocked{ipart}.sdf_bar.(markername).label, 2)
                
                fprintf('Adding: patient %d, part %d, %s, %s\n', ipatient, ipart, markername, SpikeDensity_timelocked{ipart}.sdf_bar.(markername).label{ilabel});
                
                % indexes for different sleep stages
                SpikeStats_windowed{ipart}.window{ilabel}.trialinfo.hyplabel(SpikeStats_windowed{ipart}.window{ilabel}.trialinfo.hyplabel == "NO_SCORE") = "AWAKE";
                SpikeTrials_timelocked{ipart}.(markername).trialinfo.hyplabel(SpikeTrials_timelocked{ipart}.(markername).trialinfo.hyplabel == "NO_SCORE") = "AWAKE";
               
                % collect dat_unit_window on units
                dat_unit_window.label(iunit)            = string(SpikeDensity_timelocked{ipart}.sdf_lin.(markername).label{ilabel});
                dat_unit_window.ipatient(iunit)         = ipatient;
                dat_unit_window.patientID(iunit)        = string(cfg{ipatient}.prefix(1:end-1));   
                dat_unit_window.ipart(iunit)            = ipart;
                dat_unit_window.ilabel(iunit)           = ilabel;
                dat_unit_window.markername(iunit)       = markername;
                dat_unit_window.cluster_group(iunit)    = string(strtrim(SpikeTrials_timelocked{ipart}.(markername).cluster_group{ilabel}));
                dat_unit_window.RPV(iunit)              = SpikeStats_windowed{ipart}.window{ilabel}.RPV;
                dat_unit_window.purity(iunit)           = SpikeTrials_timelocked{ipart}.(markername).purity(ilabel);
                
                for hyplabel = hyplabels
                    dat_unit_window.(strcat(markername, '_', hyplabel, '_count'))(iunit) = sum(SpikeTrials_timelocked{ipart}.(markername).trialinfo.hyplabel == hyplabel); % include artefacted periods
                end
                
                % check if unit responds statistically
                dat_unit_window.responsive_pos(iunit)   = false;
                dat_unit_window.responsive_neg(iunit)   = false;
                if isfield(SpikeDensity_timelocked{ipart}.stat.(markername){ilabel}, 'posclusters')
                    for ipos = 1 : size(SpikeDensity_timelocked{ipart}.stat.(markername){ilabel}.posclusters, 2)
                        if SpikeDensity_timelocked{ipart}.stat.(markername){ilabel}.posclusters(ipos).prob < 0.01
                            dat_unit_window.responsive_pos(iunit) = true;
                        end
                    end
                end
                if isfield(SpikeDensity_timelocked{ipart}.stat.(markername){ilabel}, 'negclusters')
                    for ineg = 1 : size(SpikeDensity_timelocked{ipart}.stat.(markername){ilabel}.negclusters, 2)
                        if SpikeDensity_timelocked{ipart}.stat.(markername){ilabel}.negclusters(ineg).prob < 0.01
                            dat_unit_window.responsive_neg(iunit) = true;
                        end
                    end
                end

                indx_clean = ~SpikeStats_windowed{ipart}.window{ilabel}.trialinfo.artefact;
                for fn1 = ["trialfreq", "trialfreq_corrected", "CV2_intraburst_trial", "LV_trial", "IR_trial" ,"SI_trial" ,"CV_trial", "CV2_trial", "amplitude", "burst_trialsum"]
                    
                    dat_unit_window.(strcat(fn1, '_avg'))(iunit) = nanmean(SpikeStats_windowed{ipart}.window{ilabel}.(fn1)(indx_clean));
                    dat_unit_window.(strcat(fn1, '_std'))(iunit) = nanstd(SpikeStats_windowed{ipart}.window{ilabel}.(fn1)(indx_clean));
                    
                    for hyplabel = hyplabels
                        trials = SpikeStats_windowed{ipart}.window{ilabel}.trialinfo.hyplabel == hyplabel & indx_clean;
                        dat_unit_window.(strcat(fn1, '_', hyplabel, '_avg'))(iunit, :) = nanmean(SpikeStats_windowed{ipart}.window{ilabel}.(fn1)(trials));
                        dat_unit_window.(strcat(fn1, '_', hyplabel, '_std'))(iunit, :) = nanstd(SpikeStats_windowed{ipart}.window{ilabel}.(fn1)(trials));
                    end
                end

                dat_unit_window.sdf_lin_avg(iunit, :)  = SpikeDensity_timelocked{ipart}.sdf_lin.(markername).avg(ilabel);
                dat_unit_window.sdf_bar_avg(iunit, :)  = SpikeDensity_timelocked{ipart}.sdf_bar.(markername).avg(ilabel);
                dat_unit_window.sdf_lin_time(iunit, :) = SpikeDensity_timelocked{ipart}.sdf_lin.(markername).time;
                dat_unit_window.sdf_bar_time(iunit, :) = SpikeDensity_timelocked{ipart}.sdf_bar.(markername).time;
                
                for hyplabel = hyplabels
                    trials = SpikeTrials_timelocked{ipart}.(markername).trialinfo.hyplabel == hyplabel;
                    dat_unit_window.(strcat('sdf_lin_avg_', hyplabel))(iunit, :) = squeeze(nanmean(SpikeDensity_timelocked{ipart}.sdf_lin.(markername).trial(trials, ilabel, :), 1))';                    
                    dat_unit_window.(strcat('sdf_bar_avg_', hyplabel))(iunit, :) = squeeze(nanmean(SpikeDensity_timelocked{ipart}.sdf_bar.(markername).trial(trials, ilabel, :), 1))';          
                end  

                iunit = iunit + 1;
            end
        end % marker
        
    end % part 
end % patient

clear SpikeTrials_timelocked SpikeDensity_timelocked SpikeStats_windowed




%% save results

% data per IED
writetable(dat_unit_IED, fullfile(cfg{1}.datasavedir, 'stats_lfp'));

% data per unit
save(fname_out, 'dat_unit_window', 'dat_unit_IED', 'dat_hyp', '-v7.3');

% summary per patient
summary_stats_unit = table;
for ipatient = 1 : 7
    summary_stats_unit.patientID(ipatient) = string(cfg{ipatient}.prefix(1:end-1));
end
summary_stats_unit.units             = groupcounts(dat_unit_window.ipatient(dat_unit_window.markername == "combined1"));
summary_stats_unit.responsive        = splitapply(@sum, (dat_unit_window.responsive_pos | dat_unit_window.responsive_neg) & dat_unit_window.markername == "combined1", dat_unit_window.ipatient);
summary_stats_unit.responsive_perc   = round(summary_stats_unit.responsive ./ summary_stats_unit.units * 100);
summary_stats_unit.SUA               = splitapply(@sum, dat_unit_window.cluster_group=="good" & dat_unit_window.markername == "combined1", dat_unit_window.ipatient);
summary_stats_unit.MUA               = splitapply(@sum, dat_unit_window.cluster_group=="mua"  & dat_unit_window.markername == "combined1", dat_unit_window.ipatient);
writetable(summary_stats_unit, fullfile(cfg{1}.datasavedir, 'summary_stats_units'));

% summary per night x type
summary_stats_unit_ext               = groupcounts(dat_unit_window(dat_unit_window.markername == "combined1", :), {'ipatient', 'ipart', 'cluster_group'});
writetable(summary_stats_unit_ext, fullfile(cfg{1}.datasavedir, 'summary_stats_units_extended'));





% 
% % summary per patient x IED hypnogram
% dat_hyp = table;
% for ipatient = 1 : 7
%     [~, hyp, hyp_stats]     = hypnogramMuseStats(cfg{ipatient});
%     hyp.ipatient            = repmat(ipatient, size(hyp, 1), 1);
%     dat_hyp                 = vertcat(dat_hyp, hyp);
% end
% dat_hyp.hyplabel(dat_hyp.hyplabel == "NO_SCORE") = "AWAKE";
% dat_hyp.hypID       = findgroups(categorical(dat_hyp.hyplabel, hyplabels));
% dat_unit_IED.hyplabel(dat_unit_IED.hyplabel == "NO_SCORE") = "AWAKE";
% dat_unit_IED.hyplabel    = categorical(dat_unit_IED.hyplabel);
% dat_unit_IED.hypID       = findgroups(categorical(dat_unit_IED.hyplabel, hyplabels));
% 
% summary_stats_hyp           = table;
% for ipatient = 1 : 7
%     for ipart = 1 : 3
%         indx                = dat_hyp.ipatient == ipatient & dat_hyp.part == ipart;
%         temp                = table;
%         temp.ipatient       = repmat(ipatient, size(hyplabels, 2), 1);
%         temp.duration       = splitapply(@sum, dat_hyp.duration(indx), dat_hyp.hypID(indx));
%         temp.hyplabel       = hyplabels';
%         temp.ipart          = repmat(ipart, size(hyplabels, 2), 1);
%         summary_stats_hyp   = vertcat(summary_stats_hyp, temp);
%     end
% end
% 
% indx = dat_unit_IED.markername == "combined1";
% [GC, GR] = groupcounts([dat_unit_IED.ipatient(indx), dat_unit_IED.ipart(indx), dat_unit_IED.hypID(indx)])
% 
% 
% x = 1:5;
% [m, mci, sem] = grpstats(summary_stats_hyp.rel, summary_stats_IED.hypID, {'mean','meanci', 'sem'});
% 
% fig = figure; hold;
% b = errorbar(x, m, sem, 'LineStyle', 'none'); b.Color = 'k';
% bar(x, m, 'k');
% set(gca,'Xtick', x, 'XTickLabel', hyplabels)
% xlim([0.5 5.5]); xtickangle(45)
% plot([0.5, 5], [1 1], ':k');
% ylabel('relative to AWAKE');
% 
% fig.Renderer = 'Painters'; % Else pdf is saved to bitmap
% set(fig,'PaperOrientation','landscape');
% set(fig,'PaperUnits','normalized');
% set(fig,'PaperPosition', [0 0 1 1]);
% fname = fullfile(cfg{1}.imagesavedir, 'GA_IEDcount_x_hypnogram');
% print(fig, '-dpdf', fname);
% 
% % ttests
% 
% [h,p,ci,stats] = ttest2(summary_stats_IED.GroupCount(summary_stats_IED.hyplabel == "AWAKE"), summary_stats_IED.GroupCount(summary_stats_IED.hyplabel == "PHASE_2"))
% 
% 
% for iID = 1:5
%     hyp_matrix(:, iID) = summary_stats_IED.rel(summary_stats_IED.hypID == iID);
% end
% 
% [p,tbl,stats] = anova1(hyp_matrix)


% % dat_unit_window_sel = dat_unit_window(dat_unit_window.markername == "combined1" & dat_unit_window.cluster_group == "good" & (dat_unit_window.responsive_neg == true | dat_unit_window.responsive_pos == true), :);
% % 
% stages.amplitude           = [dat_unit_window_sel.amplitude_REM_avg, dat_unit_window_sel.amplitude_AWAKE_avg, dat_unit_window_sel.amplitude_PHASE_1_avg, dat_unit_window_sel.amplitude_PHASE_2_avg, dat_unit_window_sel.amplitude_PHASE_3_avg];
% stages.freq                = [dat_unit_window_sel.trialfreq_REM_avg, dat_unit_window_sel.trialfreq_AWAKE_avg, dat_unit_window_sel.trialfreq_PHASE_1_avg, dat_unit_window_sel.trialfreq_PHASE_2_avg, dat_unit_window_sel.trialfreq_PHASE_3_avg];
% stages.freq_rel            = freq ./ freq(:, 2);
% stages.freq_corrected      = [dat_unit_window_sel.trialfreq_corrected_REM_avg, dat_unit_window_sel.trialfreq_corrected_AWAKE_avg, dat_unit_window_sel.trialfreq_corrected_PHASE_1_avg, dat_unit_window_sel.trialfreq_corrected_PHASE_2_avg, dat_unit_window_sel.trialfreq_corrected_PHASE_3_avg];
% stages.freq_corrected_rel  = freq ./ freq(:, 2);
% stages.bursts              = [dat_unit_window_sel.burst_trialsum_REM_avg, dat_unit_window_sel.burst_trialsum_AWAKE_avg, dat_unit_window_sel.burst_trialsum_PHASE_1_avg, dat_unit_window_sel.burst_trialsum_PHASE_2_avg, dat_unit_window_sel.burst_trialsum_PHASE_3_avg];
% stages.bursts_rel          = bursts ./ nanmean(bursts, 2);
% stages.CV2                 = [dat_unit_window_sel.CV_trial_REM_avg, dat_unit_window_sel.CV_trial_AWAKE_avg, dat_unit_window_sel.CV_trial_PHASE_1_avg, dat_unit_window_sel.CV_trial_PHASE_2_avg, dat_unit_window_sel.CV_trial_PHASE_3_avg];

set(groot,'defaultAxesTickLabelInterpreter','none');  

figure;
iplot = 1;
clear y
for fn = ["amplitude", "trialfreq_corrected", "burst_trialsum", "CV2_trial"]
    
    for istage = 1 : size(hyplabels, 2)
        y(:, istage) = dat_unit_window.(strcat(fn,'_', hyplabels(istage), '_avg'));
    end
    y_rel = y ./ mean(y, 2); 
    
    indx_single     = dat_unit_window.markername == "combined1";
    indx_good       = dat_unit_window.cluster_group == "good";
    indx_responsive = (dat_unit_window.responsive_neg == true | dat_unit_window.responsive_pos == true);
    
    subplot(2, 4, iplot); hold;
%     b = errorbar([1:5], nanmean(y(indx_single, :)), nanstd(y(indx_single, :)) / sqrt(size(y(indx_single, :), 2)),'k'); 
    b = errorbar([1:5]+0.01, nanmean(y(indx_single & indx_good, :)), nanstd(y(indx_single & indx_good, :)) / sqrt(size(y(indx_single & indx_good, :), 2)),'g:'); b.Bar.LineStyle = 'dotted';
    b = errorbar([1:5]-0.01, nanmean(y(indx_single & ~indx_good, :)), nanstd(y(indx_single & ~indx_good, :)) / sqrt(size(y(indx_single & ~indx_good, :), 2)),'r:'); b.Bar.LineStyle = 'dotted';
    b = errorbar([1:5]+0.01, nanmean(y(indx_single & indx_good & indx_responsive, :)), nanstd(y(indx_single & indx_good & indx_responsive, :)) / sqrt(size(y(indx_single & indx_good & indx_responsive, :), 2)),'g');
    b = errorbar([1:5]-0.01, nanmean(y(indx_single & ~indx_good & indx_responsive, :)), nanstd(y(indx_single & ~indx_good & indx_responsive, :)) / sqrt(size(y(indx_single & ~indx_good & indx_responsive, :), 2)),'r');
    title(fn, 'interpreter', 'none');
    xticks(1:5);
    xticklabels(hyplabels); xtickangle(45);
    xlim([0.5, 5.5]);

    subplot(2, 4, iplot+4); hold;
%     b = errorbar([1:5], nanmean(y_rel(indx_single, :)), nanstd(y_rel(indx_single, :)) / sqrt(size(y_rel(indx_single, :), 2)),'k'); 
    b = errorbar([1:5]+0.01, nanmean(y_rel(indx_single & indx_good, :)), nanstd(y_rel(indx_single & indx_good, :)) / sqrt(size(y_rel(indx_single & indx_good, :), 2)),'g:'); b.Bar.LineStyle = 'dotted';
    b = errorbar([1:5]-0.01, nanmean(y_rel(indx_single & ~indx_good, :)), nanstd(y_rel(indx_single & ~indx_good, :)) / sqrt(size(y_rel(indx_single & ~indx_good, :), 2)),'r:'); b.Bar.LineStyle = 'dotted';
    b = errorbar([1:5]+0.01, nanmean(y_rel(indx_single & indx_good & indx_responsive, :)), nanstd(y_rel(indx_single & indx_good & indx_responsive, :)) / sqrt(size(y_rel(indx_single & indx_good & indx_responsive, :), 2)),'g');
    b = errorbar([1:5]-0.01, nanmean(y_rel(indx_single & ~indx_good & indx_responsive, :)), nanstd(y_rel(indx_single & ~indx_good & indx_responsive, :)) / sqrt(size(y_rel(indx_single & ~indx_good & indx_responsive, :), 2)),'r');
    title(fn, 'interpreter', 'none');
    xticks(1:5);
    xticklabels(hyplabels); xtickangle(45);
    xlim([0.5, 5.5]);    
    
    iplot = iplot + 1;

end

%%








%%



% baseline correction
clear dat_unit_window_bl
baseline_all = [-0.5 -0.2];
baseline_hyp = [dat_unit_window{1}.time(1) dat_unit_window{1}.time(end)]; % extract from dat_unit_window - max 


for iunit = 1 : size(dat_unit_window, 2)
    
    fprintf('Processing %d of %d', iunit, size(dat_unit_window, 2));
    
    cfgtemp                 = [];
    cfgtemp.latency         = baseline_all;
    sel                     = ft_selectdat_unit_windowa(cfgtemp, dat_unit_window{iunit});
    bl                      = nanmean(sel.avg);
    dat_unit_window_bl{iunit}           = dat_unit_window{iunit};
    dat_unit_window_bl{iunit}.avg       = (dat_unit_window{iunit}.avg ./ bl) * 100;
    dat_unit_window_bl_norm{iunit}      = dat_unit_window{iunit};
    dat_unit_window_bl_norm{iunit}.avg  = ((dat_unit_window{iunit}.avg - bl) ./ (dat_unit_window{iunit}.avg + bl)) * 100;
    
    for hyplabel = hyplabels
        cfgtemp                                 = [];
        cfgtemp.latency                         = baseline_hyp;
        sel                                     = ft_selectdat_unit_windowa(cfgtemp, dat_unit_window_hyp.(hyplabel){iunit});
        bl                                      = nanmean(sel.avg);
        dat_unit_window_hyp_bl.(hyplabel){iunit}            = dat_unit_window_hyp.(hyplabel){iunit};
        dat_unit_window_hyp_bl.(hyplabel){iunit}.avg        = (dat_unit_window_hyp_bl.(hyplabel){iunit}.avg ./ bl) * 100;
        dat_unit_window_hyp_bl_norm.(hyplabel){iunit}       = dat_unit_window_hyp.(hyplabel){iunit};
        dat_unit_window_hyp_bl_norm.(hyplabel){iunit}.avg   = ((dat_unit_window_hyp.(hyplabel){iunit}.avg + bl) ./ (dat_unit_window_hyp.(hyplabel){iunit}.avg - bl)) * 100;
    end
    
end

% combine all with units as repetitions
cfgtemp                     = [];
cfgtemp.keepindividual      = 'yes';
GA                          = ft_timelockgrandaverage(cfgtemp, dat_unit_window{:}); 
GA_bl                       = ft_timelockgrandaverage(cfgtemp, dat_unit_window_bl{:}); 
GA_bl_norm                  = ft_timelockgrandaverage(cfgtemp, dat_unit_window_bl_norm{:}); 

clear dat_unit_window dat_unit_window_bl dat_unit_window_nl_norm

for hyplabel = hyplabels
    GA_hyp.(hyplabel)           = ft_timelockgrandaverage(cfgtemp, dat_unit_window_hyp.(hyplabel){:});
    GA_hyp_bl.(hyplabel)        = ft_timelockgrandaverage(cfgtemp, dat_unit_window_hyp_bl.(hyplabel){:});
    GA_hyp_bl_norm.(hyplabel)   = ft_timelockgrandaverage(cfgtemp, dat_unit_window_hyp_bl_norm.(hyplabel){:});
end

cfgtemp                                         = [];
cfgtemp.statistic                               = 'ft_statfun_correlationT';
cfgtemp.alpha                                   = 0.05;
cfgtemp.clusteralpha                            = 0.05;
cfgtemp.method                                  = 'montecarlo';
cfgtemp.computestat                             = 'yes';
cfgtemp.correctm                                = 'cluster';
cfgtemp.parameter                               = 'individual';
% cfgtemp.latency                                 = [cfg.stats.bl.(markername)(2) sdf_bar{ipart}.time(end)]; % active perio starts after baseline
cfgtemp.ivar                                    = 1;
% cfgtemp.uvar                                    = 2;
cfgtemp.design(1, :)                            = [ones(1, size(GA_bl.individual, 1)) ones(1, size(GA_bl.individual, 1))*2 ones(1, size(GA_bl.individual, 1))*3 ones(1, size(GA_bl.individual, 1))*4 ones(1, size(GA_bl.individual, 1))*5];
% cfgtemp.design(2, :)                            = [1 :  size(GA_bl.individual, 1), 1 :  size(GA_bl.individual, 1), 1 :  size(GA_bl.individual, 1), 1 :  size(GA_bl.individual, 1), 1 :  size(GA_bl.individual, 1) ];
cfgtemp.numrandomization                        = 1000;
stats                                           = ft_timelockstatistics(cfgtemp, GA_hyp.AWAKE, GA_hyp.REM, GA_hyp.PHASE_1, GA_hyp.PHASE_2, GA_hyp.PHASE_3);

% create average LFPs
for ipatient = 1 : size(LFP, 2)
    for ipart = 1 : 3
        for markername = string(unique(cfg{ipatient}.editmarkerfile.torename(:, 2))')
            LFP_avg{ipatient}{ipart}.(markername) = ft_timelockanalysis([], LFP{ipatient}{ipart}.(markername));
        end
    end
end

%% PLOTTING

xl = [-0.2 0.6];
nrows = 4;
fig = figure;
set(gcf, 'position', get(0,'ScreenSize'));
set(fig, 'PaperOrientation', 'portrait');
set(fig, 'PaperUnits', 'normalized');
set(fig, 'PaperPosition', [0 0 1 1]);

channel = 1;
cm  = cool(5);

% FIRST ROW: LFP 
for icol = 1 : 6
    subplot(nrows, 6, icol);
    title('LFP');
    hold;
    itemp = 1;
    clear y
    for ipatient = 1 : size(LFP, 2)
        for ipart = 1 : 3
            for markername = string(unique(cfg{ipatient}.editmarkerfile.torename(:, 2))')
                x = LFP_avg{ipatient}{ipart}.(markername).time;
                y(itemp, :) = LFP_avg{ipatient}{ipart}.(markername).avg(channel, :);
                lh = plot(x, y(itemp, :), 'k');
                lh.Color        = [0,0,0,0.3];
                itemp = itemp + 1;
            end
        end
    end
    plot(x, nanmean(y, 1), 'k', 'linewidth', 3);
    plot(x, nanmean(y, 1), 'w', 'linewidth', 2);
    ylabel('Current');
    axis tight
    xlim(xl);
end

% SECOND ROW: FIRING RATE
subplot(nrows, 6, 7);
title('Firing rate');
hold on
clear y
iunit = 1;
for indx = find(trialinfo.responsive & trialinfo.cluster_group == "good ")'
    x               = GA.time;
    y(iunit,:)      = squeeze(GA_bl.individual(indx, 1, :));
    lh              = plot(x, y(iunit, :), 'k');
    lh.Color        = [0,0,0,0.1];
    iunit           = iunit + 1;
end
plot(x, nanmean(y, 1), 'k', 'linewidth', 3);
plot(x, nanmean(y, 1), 'w', 'linewidth', 2);
ylabel('Firing rate vs. baseline');
axis tight
xlim(xl);

subplot(nrows, 6, 8);
hold on
clear y
iunit = 1;
for indx = find(trialinfo.responsive & trialinfo.cluster_group == "good ")'
    x               = GA.time;
    y(iunit,:)      = squeeze(GA_bl_norm.individual(indx, 1, :));
    lh              = plot(x, y(iunit, :), 'k');
    lh.Color        = [0,0,0,0.1];
    iunit           = iunit + 1;    
end
plot(x, nanmean(y, 1), 'k', 'linewidth', 3);
plot(x, nanmean(y, 1), 'w', 'linewidth', 2);
ylabel('Firing rate change (norm. %)');
ylim([-100, 100]);
axis tight
xlim(xl);

subplot(nrows, 6, 9);
hold on
clear y
iunit = 1;
for indx = find(trialinfo.responsive & trialinfo.cluster_group == "good ")'
    x               = GA.time;
    y(iunit,:)      = squeeze(GA_bl.individual(indx, 1, :));
    lh              = plot(x, y(iunit, :), 'k');
    lh.Color        = [0,0,0,0.1];
    iunit           = iunit + 1;       
end
plot(x, nanmean(y, 1), 'k', 'linewidth', 3);
plot(x, nanmean(y, 1), 'w', 'linewidth', 2);
ylabel('Firing rate (log(Hz))');
axis tight
set(gca, 'YScale', 'log');

subplot(nrows, 6, 10);
hold on
clear y
iunit = 1;
for indx = find(trialinfo.responsive & trialinfo.cluster_group == "mua  ")'
    x               = GA.time;
    y(iunit,:)      = (squeeze(GA_bl.individual(indx, 1, :)));
    lh              = plot(x, y(iunit, :), 'k');
    lh.Color        = [0,0,0,0.1];
    iunit           = iunit + 1;
end
plot(x, nanmean(y, 1), 'k', 'linewidth', 3);
plot(x, nanmean(y, 1), 'w', 'linewidth', 2);
ylabel('Firing rate (Hz)');
axis tight

subplot(nrows, 6, 11);
hold on
clear y
for indx = find(trialinfo.responsive & trialinfo.cluster_group == "mua  ")'
    x               = GA.time;
    y(iunit,:)      = (squeeze(GA_bl_norm.individual(indx, 1, :)));
    lh              = plot(x, y(iunit, :), 'k');
    lh.Color        = [0,0,0,0.1];
    iunit           = iunit + 1; 
end
plot(x, nanmean(y, 1), 'k', 'linewidth', 3);
plot(x, nanmean(y, 1), 'w', 'linewidth', 2);
ylabel('Firing rate change (norm. %)');
ylim([-100, 100]);
axis tight

subplot(nrows, 6, 12);
hold on
clear y
iunit = 1;
for indx = find(trialinfo.responsive & trialinfo.cluster_group == "mua  ")'
    x               = GA.time;
    y(iunit,:)      = (squeeze(GA_bl.individual(indx, 1, :)));
    lh              = plot(x, y(iunit, :), 'k');
    lh.Color        = [0,0,0,0.1];
    iunit           = iunit + 1;    
end
plot(x, nanmean(y, 1), 'k', 'linewidth', 3);
plot(x, nanmean(y, 1), 'w', 'linewidth', 2);
ylabel('Firing rate (log(Hz))');
axis tight
set(gca, 'YScale', 'log');

% THIRD ROW: FIRING RATE PER HYPNOGRAM
subplot(nrows, 6, 13);
hold on
clear y
ihyp = 1;
for hyplabel = hyplabels
    x = GA_bl.time;
    iunit = 1;
    indxs = find(trialinfo.responsive & trialinfo.cluster_group == "good ")';
    for indx = indxs
        lh = plot(x, squeeze(GA_hyp.(hyplabel).individual(indx, 1, :)), 'k');
        lh.Color = [cm(ihyp, :), 0.1];
        iunit = iunit + 1;
    end
    ihyp = ihyp + 1;
end

i = 1;
for hyplabel = hyplabels
    plot(x, nanmean(squeeze(GA_hyp.(hyplabel).individual(indxs, 1, :)), 1), 'k', 'linewidth', 3);
    plot(x, nanmean(squeeze(GA_hyp.(hyplabel).individual(indxs, 1, :)), 1), 'color', cm(i, :), 'linewidth', 2);
    i = i + 1;
end
ylabel('Firing rate');
xlim(xl);


subplot(nrows, 6, 14);
hold on
clear y
ihyp = 1;
for hyplabel = hyplabels
    x = GA_bl.time;
    iunit = 1;
    indxs = find(trialinfo.responsive & trialinfo.cluster_group == "good ")';
    for indx = indxs
        lh = plot(x, squeeze(GA_hyp_bl.(hyplabel).individual(indx, 1, :)), 'k');
        lh.Color = [cm(ihyp, :), 0.1];
        iunit = iunit + 1;
    end
    ihyp = ihyp + 1;
end

i = 1;
for hyplabel = hyplabels
    plot(x, nanmean(squeeze(GA_hyp_bl.(hyplabel).individual(indxs, 1, :)), 1), 'k', 'linewidth', 3);
    plot(x, nanmean(squeeze(GA_hyp_bl.(hyplabel).individual(indxs, 1, :)), 1), 'color', cm(i, :), 'linewidth', 2);
    i = i + 1;
end
axis tight
ylabel('Firing rate');
xlim(xl);


subplot(nrows, 6, 15);
hold on
clear y
ihyp = 1;
for hyplabel = hyplabels
    x = GA_bl.time;
    iunit = 1;
    indxs = find(trialinfo.responsive & trialinfo.cluster_group == "good ")';
    for indx = indxs
        lh = plot(x, squeeze(GA_hyp_bl.(hyplabel).individual(indx, 1, :)), 'k');
        lh.Color = [cm(ihyp, :), 0.1];
        iunit = iunit + 1;
    end
    ihyp = ihyp + 1;
end

i = 1;
for hyplabel = hyplabels
    plot(x, nanmean(squeeze(GA_hyp_bl.(hyplabel).individual(indxs, 1, :)), 1), 'k', 'linewidth', 3);
    plot(x, nanmean(squeeze(GA_hyp_bl.(hyplabel).individual(indxs, 1, :)), 1), 'color', cm(i, :), 'linewidth', 2);
    i = i + 1;
end
axis tight
ylabel('Firing rate');
xlim(xl);
set(gca, 'YScale', 'log');


subplot(nrows, 6, 16);
hold on
clear y
ihyp = 1;
for hyplabel = hyplabels
    x = GA_bl.time;
    iunit = 1;
    indxs = find(trialinfo.responsive & trialinfo.cluster_group == "mua  ")';
    for indx = indxs
        lh = plot(x, squeeze(GA_hyp.(hyplabel).individual(indx, 1, :)), 'k');
        lh.Color = [cm(ihyp, :), 0.1];
        iunit = iunit + 1;
    end
    ihyp = ihyp + 1;
end

i = 1;
for hyplabel = hyplabels
    plot(x, nanmean(squeeze(GA_hyp.(hyplabel).individual(indxs, 1, :)), 1), 'k', 'linewidth', 3);
    plot(x, nanmean(squeeze(GA_hyp.(hyplabel).individual(indxs, 1, :)), 1), 'color', cm(i, :), 'linewidth', 2);
    i = i + 1;
end
ylabel('Firing rate');
xlim(xl);


subplot(nrows, 6, 17);
hold on
clear y
ihyp = 1;
for hyplabel = hyplabels
    x = GA_bl.time;
    iunit = 1;
    indxs = find(trialinfo.responsive & trialinfo.cluster_group == "mua  ")';
    for indx = indxs
        lh = plot(x, squeeze(GA_hyp_bl.(hyplabel).individual(indx, 1, :)), 'k');
        lh.Color = [cm(ihyp, :), 0.1];
        iunit = iunit + 1;
    end
    ihyp = ihyp + 1;
end

i = 1;
for hyplabel = hyplabels
    plot(x, nanmean(squeeze(GA_hyp_bl.(hyplabel).individual(indxs, 1, :)), 1), 'k', 'linewidth', 3);
    plot(x, nanmean(squeeze(GA_hyp_bl.(hyplabel).individual(indxs, 1, :)), 1), 'color', cm(i, :), 'linewidth', 2);
    i = i + 1;
end
axis tight
ylabel('Firing rate');
xlim(xl);


subplot(nrows, 6, 18);
hold on
clear y
ihyp = 1;
for hyplabel = hyplabels
    x = GA_bl.time;
    iunit = 1;
    indxs = find(trialinfo.responsive & trialinfo.cluster_group == "mua  ")';
    for indx = indxs
        lh = plot(x, squeeze(GA_hyp_bl.(hyplabel).individual(indx, 1, :)), 'k');
        lh.Color = [cm(ihyp, :), 0.1];
        iunit = iunit + 1;
    end
    ihyp = ihyp + 1;
end

i = 1;
for hyplabel = hyplabels
    plot(x, nanmean(squeeze(GA_hyp_bl.(hyplabel).individual(indxs, 1, :)), 1), 'k', 'linewidth', 3);
    plot(x, nanmean(squeeze(GA_hyp_bl.(hyplabel).individual(indxs, 1, :)), 1), 'color', cm(i, :), 'linewidth', 2);
    i = i + 1;
end
axis tight
ylabel('Firing rate');
xlim(xl);
set(gca, 'YScale', 'log');

for iplot = 0 : 5
    
    % Forth row: statistics
    subplot(nrows, 6, 19 + iplot); hold;
    plot(stats.time, stats.rho, 'k');
    ylabel('Correlation {\it r}');
    yyaxis right
    set(gca,'YColor','k');
    lh = plot(stats.time, stats.stat);
    lh.Color        = [0,0,0,0]; % turn fully transparant
    
    ylabel('t');
    axis tight
    ax = axis;
    for ineg = 1 : size(stats.negclusters)
        if stats.negclusters(ineg).prob < 0.025
            x(1) = stats.time(find(stats.negclusterslabelmat == ineg, 1, 'first'));
            x(2) = stats.time(find(stats.negclusterslabelmat == ineg, 1, 'last'));
            height = ax(4) - (ax(4) - ax(3))*0.05;
            text(x(1)+0.1, height, sprintf('p = %.3f', stats.negclusters(ineg).prob), 'HorizontalAlignment', 'left', 'fontsize', 8);
            patch([x(1), x(2), x(2), x(1)], [ax(3), ax(3), ax(4), ax(4)], [1 0 0], 'facealpha', 0.1, 'edgecolor', 'none');
        end
    end
    for ipos = 1 : size(stats.posclusters)
        if stats.posclusters(ipos).prob < 0.025
            x(1) = stats.time(find(stats.posclusterslabelmat == ipos, 1, 'first'));
            x(2) = stats.time(find(stats.posclusterslabelmat == ipos, 1, 'last'));
            height = ax(4) - (ax(4) - ax(3))*0.05;
            text(x(1)+0.1, height, sprintf('p = %.3f', stats.posclusters(ipos).prob), 'HorizontalAlignment', 'left', 'fontsize', 6);
            patch([x(1), x(2), x(2), x(1)], [ax(3), ax(3), ax(4), ax(4)], [0 1 0], 'facealpha', 0.1, 'edgecolor', 'none');
        end
    end
    plot([ax(1), ax(2)],[0 0],'k:');
    set(gca,'children',flipud(get(gca,'children')));
    xlim(xl);
    
end

% print ISI to file
fig.Renderer = 'Painters'; % Else pdf is saved to bitmap
set(fig,'PaperOrientation','landscape');
set(fig,'PaperUnits','normalized');
set(fig,'PaperPosition', [0 0 1 1]);
fname = fullfile(cfg{1}.imagesavedir, 'GA');
print(fig, '-dpdf', fname);
print(fig, '-djpeg', fname, '-r1200');

disp(['Export fig ', fname])
export_fig(fname, '-png'); % need to install https://www.ghostscript.com/download/gsdnld.html
close all



