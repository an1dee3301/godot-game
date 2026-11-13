#!/usr/bin/env python3
"""Run real ENet host/client, late-join and unreachable-host processes."""
import json,pathlib,socket,subprocess,tempfile,time,sys,os,shutil
PROJECT=pathlib.Path(__file__).resolve().parents[1]
ENGINE=os.environ.get('GODOT_EXECUTABLE') or shutil.which('godot') or '/Applications/Godot.app/Contents/MacOS/Godot'
def free_port():
    with socket.socket(socket.AF_INET,socket.SOCK_DGRAM) as sock:
        sock.bind(('127.0.0.1',0));return sock.getsockname()[1]
port=free_port();unused_port=free_port()
with tempfile.TemporaryDirectory(prefix='trust-party-network-') as directory:
    root=pathlib.Path(directory);processes=[]
    def launch(role,chosen_port):
        logfile=(root/(role+'.log')).open('w');report=root/(role+'.json')
        args=[ENGINE,'--headless','--path',str(PROJECT),'--script','res://tests/network_peer_test.gd','--',f'--network-test-role={role}',f'--network-test-port={chosen_port}',f'--network-test-report={report}']
        proc=subprocess.Popen(args,stdout=logfile,stderr=subprocess.STDOUT)
        processes.append((role,proc,logfile,report))
    launch('host',port);time.sleep(0.8);launch('client',port);launch('failure',unused_port)
    wait_until=time.monotonic()+10
    while time.monotonic()<wait_until:
        if 'NETWORK_MATCH_STARTED' in (root/'host.log').read_text():break
        time.sleep(0.05)
    launch('late',port)
    failed=False;total_checks=0
    try:
        for role,proc,logfile,report in processes:
            try:code=proc.wait(timeout=48)
            except subprocess.TimeoutExpired:proc.kill();code=124
            logfile.close();log=(root/(role+'.log')).read_text()
            if code or 'SCRIPT ERROR' in log or 'ERROR:' in log or 'leaked at exit' in log or 'above the MTU' in log:failed=True
            # Keep failures readable even if an engine error repeats every tick.
            lines=log.splitlines()
            print(log if len(lines)<100 else '\n'.join(lines[:60]+['...']+lines[-20:]))
            if report.exists():
                data=json.loads(report.read_text());print(json.dumps(data,indent=2));total_checks+=data['checks']
                if data['failures']:failed=True
            else:failed=True;print(role,'did not produce report')
    finally:
        for _,proc,logfile,_ in processes:
            if proc.poll() is None:proc.kill()
            if not logfile.closed:logfile.close()
    print('NETWORK INTEGRATION:', 'FAILED' if failed else f'PASSED ({total_checks} checks, four independent ENet processes)')
    sys.exit(1 if failed else 0)
