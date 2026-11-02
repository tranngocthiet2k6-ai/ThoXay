import sys,unittest,tempfile
from pathlib import Path
from unittest.mock import Mock,patch
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
import demo_photos

class DemoPhotosTests(unittest.TestCase):
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
