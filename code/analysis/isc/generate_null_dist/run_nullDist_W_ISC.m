% run_nullDist_W_ISC.m
% Example driver for nullDist_W_ISC on a Linux VM
%
% Author: Yohay Zvi, June 2023
% Checked: May 2025


iter_number = 1000;
scriptNum = 1;
tasks = ["kosher", "hammetz", "neutral"];
groupsNames = ["Religious", "Secular"];
dataMat_path = 'data/fMRI/data_mat_combined/';

for task_ind = 1:length(tasks)
    for group_ind = 1:length(groupsNames)
        start_time = tic;
        sprintf ("started working on group number %.0f, task number %.0f\n\n", group_ind, task_ind)
        load (strcat(dataMat_path,groupsNames(group_ind), "_Combined_task_", tasks(task_ind)))
        fileName = strcat("W_ISC_nullDist_",groupsNames(group_ind),"_",tasks(task_ind),"_", scriptNum);
        
        output_path = '/religion-neuro-sync/data/fMRI/null_dist/isc';

        % potentially split into multiple consecutive sessions 
        if tasks(task_ind) == "kosher" && groupsNames(group_ind) == "Religious"
            iter_number = 1;
        elseif tasks(task_ind) == "hammetz" && groupsNames(group_ind) == "Religious"
            iter_number = 323;

        end
        
        nullDist_W_ISC(dataMat_combined,iter_number, output_path, fileName)
        one_mat_time = toc (start_time);
        msg = sprintf("Finished working on task number %.0f from group number %.0f\nIt took %d seconds\n\n", task_ind, group_ind,one_mat_time);
        disp (msg)
    end
end




       
