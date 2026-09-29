cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
r = system('start /min cmd /c experiments\run_v2_diag.bat');
disp(['launch rc=' num2str(r)]);
