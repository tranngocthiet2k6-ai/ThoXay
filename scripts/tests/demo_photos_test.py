import sys,unittest,tempfile
from pathlib import Path
from unittest.mock import Mock,MagicMock,patch
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
import demo_photos

class DemoPhotosTests(unittest.TestCase):
    def test_existing_work_photos_are_preserved_and_only_seed_illustrations_replaced(self):
        conn=MagicMock();cursor=conn.cursor.return_value.__enter__.return_value
        cursor.fetchall.side_effect=[[],[(91,demo_photos.illustration('TOAN CANH - DEMO'),None,3),(92,b'user replacement',b'custom detail',7)]]
        with patch.object(demo_photos,'validate_target'):
            demo_photos.enrich(conn,Path(__file__).resolve().parents[2]/'docs/demo_photos')
        changes=[c for c in cursor.execute.call_args_list if c.args[0].startswith('UPDATE work_logs')]
        self.assertEqual(len(changes),1)
        self.assertEqual(changes[0].args[1][-2:],(91,3))
        self.assertIn('version=version+1',changes[0].args[0])
    def test_refused_database_never_reads_photos_or_changes_rows(self):
        conn=Mock()
        with patch.object(demo_photos,'validate_target',side_effect=ValueError('not demo')):
            with self.assertRaises(ValueError): demo_photos.enrich(conn,Path('missing'))
        conn.cursor.assert_not_called()

    def test_invalid_asset_never_mutates_demo(self):
        conn=Mock()
        with tempfile.TemporaryDirectory() as tmp:
            for name,_ in demo_photos.PHOTOS:(Path(tmp)/(name+'.jpg')).write_bytes(b'invalid')
            with patch.object(demo_photos,'validate_target'):
                with self.assertRaises(ValueError):demo_photos.enrich(conn,Path(tmp))
        conn.cursor.assert_not_called()

if __name__=='__main__':unittest.main()
