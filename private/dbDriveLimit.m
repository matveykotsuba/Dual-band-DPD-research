function [y,info] = dbDriveLimit(x,c)
    if any(~isfinite(x)), error('dbDriveLimit:Nonfinite','DPD produced a nonfinite drive.'); end
    magnitude=abs(x); clipped=magnitude>c.maximumDrivePeak;
    y=x; y(clipped)=x(clipped).*(c.maximumDrivePeak./magnitude(clipped));
    info.clippedFraction=mean(clipped); info.rawPeak=max(magnitude);
end
