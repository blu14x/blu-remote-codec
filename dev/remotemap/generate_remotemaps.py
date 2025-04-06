from dev.remotemap.xtouch_remotemap import remote_map as xtouch_remote_map
from dev.remotemap.remotemap import RemoteMapFileWriter

for remote_map in (xtouch_remote_map,):
    file_writer = RemoteMapFileWriter(remote_map)
    file_writer.generate_file()
