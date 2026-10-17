"""Production ordering tests; no build, cloud access or real installation."""
import argparse
import importlib.util
from pathlib import Path
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("production", Path(__file__).resolve().parents[1] / "build_production.py")
production = importlib.util.module_from_spec(spec)
spec.loader.exec_module(production)


class ProductionTests(unittest.TestCase):
    def exercise(self, fail_bundle=False):
        trace = []
        args = argparse.Namespace(windows=True, web=True, apk=True, bundle=True, all=False,
                                  deploy=True, skip_pub_get=True, no_bump=True, bump_build=False, bump=None)
        def bundle(*args):
            trace.append("bundle")
            if fail_bundle:
                raise SystemExit(1)
            return Path(__file__)
        with patch.object(production, 'parse_args', return_value=args), \
             patch.object(production, 'read_version', return_value=('1.0.6','8')), \
             patch.object(production, 'ensure_flutter', return_value='flutter'), \
             patch.object(production, 'step_windows', side_effect=lambda *args: trace.append(('windows',args[1:])) or Path('setup.exe')), \
             patch.object(production, 'step_web', side_effect=lambda *args, **kw: trace.append(('web',kw['deploy']))), \
             patch.object(production, 'step_apk', side_effect=lambda *args: trace.append('apk') or Path(__file__)), \
             patch.object(production, 'step_bundle', side_effect=bundle), \
             patch.object(production, 'which', return_value='node'), \
             patch.object(production, 'run', side_effect=lambda command: trace.append(command)), \
             patch.object(production, 'ensure_firebase', return_value='firebase'), \
             patch.object(production.shutil, 'copytree'):
            if fail_bundle:
                with self.assertRaises(SystemExit): production.main()
            else:
                production.main()
        return trace

    def test_all_builds_precede_every_publication(self):
        trace = self.exercise()
        self.assertEqual(trace[:4], [('windows',('1.0.6','8')),('web',False),'apk','bundle'])
        self.assertEqual(trace[-1], ['firebase','deploy','--project','faca-a-festa','--only','hosting'])
        self.assertIn('--publish',trace[-2])
        self.assertFalse(any('play' in str(item).lower() for item in trace))

    def test_failure_never_publishes_a_partial_release(self):
        self.assertEqual(len(self.exercise(True)),4)


if __name__ == '__main__': unittest.main()
