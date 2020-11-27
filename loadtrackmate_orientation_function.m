function [data] = loadtrackmate_orientation_function(minnumbspots, loadstr, savestr)
    %this is for the general saved file (not for the XML track file)

    di=importdata(loadstr);
    if isempty(di)
        data=di;
        save(savestr,'data')
        return
    end
    
    TRACK_ID=di(:,2);
    POSITION_X=di(:,3);
    POSITION_Y=di(:,4);
    POSITION_T=di(:,5);    %ADDING ONE !!! (otherwise it would start at zero)
    AXIS_C=di(:,6);
    AXIS_B=di(:,7);
    PHI=di(:,8);
    MEANINTENS=di(:,9);

    p=1;
    data=[];
    for i=0:max(TRACK_ID) 
        inds=find(TRACK_ID==i);

        if isempty(inds)==0  && length(inds)>=minnumbspots
            data_temp=[];
            data_temp(:,1)=POSITION_T(inds);
            data_temp(:,2)=POSITION_X(inds);
            data_temp(:,3)=POSITION_Y(inds);
            data_temp(:,4)=AXIS_C(inds);
            data_temp(:,5)=AXIS_B(inds);
            data_temp(:,6)=PHI(inds);
            data_temp(:,7)=MEANINTENS(inds);
            data_temp=sortrows(data_temp,1);

            data(p).t=data_temp(:,1); %#ok<*AGROW>
            data(p).x=data_temp(:,2);
            data(p).y=data_temp(:,3);
            data(p).minorleng=data_temp(:,4);
            data(p).majorleng=data_temp(:,5);
            data(p).phi=data_temp(:,6);
            data(p).meanintens=data_temp(:,7);


            leng(p)=length(POSITION_T(inds));
            p=p+1;

        end
    end

    save(savestr,'data')

    clear all %#ok<CLALL>
    close all

    return