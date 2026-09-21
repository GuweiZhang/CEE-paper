pass
from pathlib import Path
import argparse, shutil, subprocess, sys, os, json, re

ROOT=Path(__file__).resolve().parent
def main():
    p=argparse.ArgumentParser()
    p.add_argument('--figures',nargs='+',default=['all'],help='all, python, or Figure1 FigureS14 ...')
    p.add_argument('--output',default=str(ROOT/'outputs/figures'))
    p.add_argument('--ncl',default='ncl')
    p.add_argument('--source-data',default=str(ROOT/'source_data'))
    args=p.parse_args()
    out=Path(args.output).resolve();out.mkdir(parents=True,exist_ok=True)
    for source in Path(args.source_data).iterdir():shutil.copy2(source,out/source.name)
    for source in (ROOT/'assets').iterdir():
        if source.is_dir():shutil.copytree(source,out/source.name,dirs_exist_ok=True)
        else:shutil.copy2(source,out/source.name)
    scripts=list((ROOT/'code/plotting').glob('*_plot.*'))
    selected=[s for s in scripts if 'all' in args.figures or s.stem.removesuffix('_plot') in args.figures or ('python' in args.figures and s.suffix=='.py')]
    if not selected:raise SystemExit('No matching figures')
    results=[]
    for s in sorted(selected):
        command=[sys.executable,str(s)] if s.suffix=='.py' else [args.ncl,str(s)]
        try:
            run=subprocess.run(command,cwd=out,env={**os.environ,'MPLBACKEND':'Agg'},capture_output=True,text=True,errors='replace')
            log=run.stdout+'\n'+run.stderr
            good=run.returncode==0 and not re.search(r'(?:fatal:|error:)',log,re.I)
        except OSError as e: log=str(e);good=False
        (out/(s.stem+'.log')).write_text(log,encoding='utf-8')
        fig=s.stem.removesuffix('_plot')
        products=[x.name for x in out.glob(fig+'.*') if x.suffix in ['.eps','.png','.pdf']]
        good=good and bool(products)
        results.append(dict(figure=fig,passed=good,outputs=products))
        print(fig,'PASS' if good else 'FAIL',flush=True)
    (out/'run_report.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
    if not all(x['passed'] for x in results):raise SystemExit('Some figures failed; see individual logs')
if __name__=='__main__':main()
