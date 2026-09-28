function RoomReverbApp
% RoomReverbApp - 厕所/长走廊空间混响模拟器
% MATLAB R2025b
% 同目录放 toilet_rir.wav 和 corridor_rir.wav
% 若没有，则可使用 tolite.m4a 和 zoulang.m4a 自动提取。
%
% 运行：
%   RoomReverbApp

audioIn=[]; audioOut=[]; fsIn=[]; playerObj=[];
[hT,fsT]=getRIR("toilet");
[hC,fsC]=getRIR("corridor");

fig=uifigure("Name","厕所 / 长走廊空间混响模拟器","Position",[120 80 1050 700]);
g=uigridlayout(fig,[6 4]);
g.RowHeight={55,45,70,230,230,45};
g.ColumnWidth={150,"1x","1x",150};
g.Padding=[15 15 15 15];

L=uilabel(g); L.Text="厕所 / 长走廊空间混响模拟器";
L.FontSize=22; L.FontWeight="bold"; L.HorizontalAlignment="center";
L.Layout.Row=1; L.Layout.Column=[1 4];

btnImport=uibutton(g,"Text","导入音频","ButtonPushedFcn",@importAudio);
btnImport.Layout.Row=2; btnImport.Layout.Column=1;

fileLabel=uilabel(g); fileLabel.Text="当前文件：未导入";
fileLabel.Layout.Row=2; fileLabel.Layout.Column=[2 4];

roomLabel=uilabel(g); roomLabel.Text="空间："; roomLabel.HorizontalAlignment="right";
roomLabel.Layout.Row=3; roomLabel.Layout.Column=1;

roomDrop=uidropdown(g);
roomDrop.Items=["厕所","长走廊"];
roomDrop.Value="厕所";
roomDrop.Layout.Row=3; roomDrop.Layout.Column=2;
roomDrop.ValueChangedFcn=@settingChanged;

mixGrid=uigridlayout(g,[2 2]);
mixGrid.Layout.Row=3; mixGrid.Layout.Column=[3 4];
mixGrid.RowHeight={22,35}; mixGrid.ColumnWidth={"1x",55}; mixGrid.Padding=[0 0 0 0];

mixLabel=uilabel(mixGrid); mixLabel.Text="混响强度（Dry / Wet）";
mixLabel.Layout.Row=1; mixLabel.Layout.Column=1;

mixValue=uilabel(mixGrid); mixValue.Text="50%"; mixValue.FontWeight="bold";
mixValue.Layout.Row=1; mixValue.Layout.Column=2;

mixSlider=uislider(mixGrid,"Limits",[0 100],"Value",50);
mixSlider.MajorTicks=[0 25 50 75 100];
mixSlider.MajorTickLabels=["0%","25%","50%","75%","100%"];
mixSlider.Layout.Row=2; mixSlider.Layout.Column=[1 2];
mixSlider.ValueChangingFcn=@sliderMoving;
mixSlider.ValueChangedFcn=@settingChanged;

ax1=uiaxes(g); ax1.Layout.Row=4; ax1.Layout.Column=[1 4];
title(ax1,"原始音频"); xlabel(ax1,"时间 / s"); ylabel(ax1,"幅度"); grid(ax1,"on");

ax2=uiaxes(g); ax2.Layout.Row=5; ax2.Layout.Column=[1 4];
title(ax2,"处理后音频"); xlabel(ax2,"时间 / s"); ylabel(ax2,"幅度"); grid(ax2,"on");

b1=uibutton(g,"Text","▶ 播放原声","Enable","off","ButtonPushedFcn",@playDry);
b1.Layout.Row=6; b1.Layout.Column=1;

b2=uibutton(g,"Text","▶ 播放处理结果","Enable","off","ButtonPushedFcn",@playWet);
b2.Layout.Row=6; b2.Layout.Column=2;

b3=uibutton(g,"Text","■ 停止","Enable","off","ButtonPushedFcn",@stopPlay);
b3.Layout.Row=6; b3.Layout.Column=3;

b4=uibutton(g,"Text","导出 WAV","Enable","off","ButtonPushedFcn",@exportWav);
b4.Layout.Row=6; b4.Layout.Column=4;

    function importAudio(~,~)
        [f,p]=uigetfile({"*.wav;*.mp3;*.m4a;*.flac","音频文件";"*.*","所有文件"},"选择音频");
        if isequal(f,0), return; end
        try
            [x,fs]=audioread(fullfile(p,f));
            if size(x,2)>1, x=mean(x,2); end
            x=x(:)-mean(x(:));
            pk=max(abs(x));
            if pk==0, error("该音频没有有效声音。"); end
            audioIn=0.95*x/pk; fsIn=fs;
            fileLabel.Text=sprintf("当前文件：%s | %.2f s | %d Hz",f,length(audioIn)/fsIn,fsIn);
            drawWave(ax1,audioIn,fsIn,"原始音频");
            b1.Enable="on"; b3.Enable="on";
            processAudio();
        catch ME
            uialert(fig,ME.message,"导入失败");
        end
    end

    function sliderMoving(~,e)
        mixValue.Text=sprintf("%.0f%%",e.Value);
    end

    function settingChanged(~,~)
        mixValue.Text=sprintf("%.0f%%",mixSlider.Value);
        if ~isempty(audioIn), processAudio(); end
    end

    function processAudio()
        try
            fig.Pointer="watch"; drawnow;
            if strcmp(roomDrop.Value,"厕所")
                h=hT; fsh=fsT; rn="厕所";
            else
                h=hC; fsh=fsC; rn="长走廊";
            end

            if fsh~=fsIn
                h=resample(h,fsIn,fsh);
            end

            h=h(:)-mean(h(:));
            h=h/max(abs(h));

            wet=conv(audioIn,h);
            rw=rms(wet); rd=rms(audioIn);
            if rw>0
                wet=wet*(rd/rw);
            end

            dry=zeros(size(wet));
            dry(1:length(audioIn))=audioIn;

            a=mixSlider.Value/100;
            audioOut=(1-a)*dry+a*wet;

            pk=max(abs(audioOut));
            if pk>0.98
                audioOut=0.98*audioOut/pk;
            end

            drawWave(ax2,audioOut,fsIn,sprintf("%s空间效果 | 混响强度 %.0f%%",rn,100*a));
            b2.Enable="on"; b4.Enable="on";
        catch ME
            uialert(fig,ME.message,"处理失败");
        end
        fig.Pointer="arrow";
    end

    function playDry(~,~)
        stopCurrent();
        playerObj=audioplayer(audioIn,fsIn);
        play(playerObj);
    end

    function playWet(~,~)
        stopCurrent();
        playerObj=audioplayer(audioOut,fsIn);
        play(playerObj);
    end

    function stopPlay(~,~)
        stopCurrent();
    end

    function stopCurrent()
        if ~isempty(playerObj)
            try, stop(playerObj); catch, end
        end
    end

    function exportWav(~,~)
        if isempty(audioOut), return; end
        if strcmp(roomDrop.Value,"厕所"), tag="toilet"; else, tag="corridor"; end
        def=sprintf("%s_reverb_%03.0f.wav",tag,mixSlider.Value);
        [f,p]=uiputfile("*.wav","导出处理后的音频",def);
        if isequal(f,0), return; end
        audiowrite(fullfile(p,f),audioOut,fsIn);
        uialert(fig,"处理后的音频已经保存。","导出成功","Icon","success");
    end

    function drawWave(ax,x,fs,ttl)
        n=max(1,ceil(length(x)/100000));
        ii=1:n:length(x); t=(ii-1)/fs;
        plot(ax,t,x(ii),"LineWidth",0.8);
        title(ax,ttl,"Interpreter","none");
        xlabel(ax,"时间 / s"); ylabel(ax,"幅度"); grid(ax,"on");
        xlim(ax,[0 max(t(end),0.01)]); ylim(ax,[-1.05 1.05]);
    end

    function [h,fs]=getRIR(room)
        if strcmp(room,"toilet")
            rf="toilet_rir.wav"; rawf="tolite.m4a"; t1=12.44; t2=13.15;
        else
            rf="corridor_rir.wav"; rawf="zoulang.m4a"; t1=13.99; t2=14.65;
        end

        if isfile(rf)
            [h,fs]=audioread(rf);
        elseif isfile(rawf)
            [z,fs]=audioread(rawf);
            if size(z,2)>1, z=mean(z,2); end
            i1=round(t1*fs)+1;
            i2=min(round(t2*fs)+1,length(z));
            h=z(i1:i2);
        else
            error("找不到 %s 或 %s。请把它们放到 Current Folder。",rf,rawf);
        end

        if size(h,2)>1, h=mean(h,2); end
        h=h(:)-mean(h(:));
        pk=max(abs(h));
        if pk==0, error("%s 没有有效声音。",rf); end
        h=h/pk;
    end
end
