import sys, unittest
from pathlib import Path
from types import SimpleNamespace
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from demo_seed import validate_target, seed

class Cursor:
    def __init__(self,rows): self.rows=iter(rows)
    def __enter__(self): return self
    def __exit__(self,*args): pass
    def execute(self,*args): pass
    def fetchone(self): return next(self.rows)
class Connection:
    def __init__(self,host='127.0.0.1',db='thoxay_defense_demo',rows=()):
        self.info=SimpleNamespace(host=host,dbname=db);self.q=Cursor(rows)
    def cursor(self): return self.q

class DemoSafetyTest(unittest.TestCase):
    def test_remote_host_is_rejected(self):
        with self.assertRaises(ValueError): validate_target(Connection(host='production.example.com'))
    def test_normal_database_is_rejected(self):
        with self.assertRaises(ValueError): validate_target(Connection(db='tho_xay_db'))
    def test_actual_server_address_is_checked(self):
        with self.assertRaises(ValueError): validate_target(Connection(rows=[('10.0.0.2','thoxay_defense_demo')]))
    def test_non_demo_user_prevents_all_writes(self):
        with self.assertRaises(ValueError): validate_target(Connection(rows=[('127.0.0.1','thoxay_defense_demo'),(1,)]))
    def test_missing_migration_prevents_seed(self):
        with self.assertRaises(ValueError): validate_target(Connection(rows=[('127.0.0.1','thoxay_defense_demo'),(0,),(0,)]))
    def test_second_seed_preserves_bank_and_demo_interactions(self):
        conn=Connection(rows=[('127.0.0.1','thoxay_defense_demo'),(0,),(1,),(8,)])
        self.assertFalse(seed(conn,Path('.local/demo')))

if __name__=='__main__': unittest.main()
