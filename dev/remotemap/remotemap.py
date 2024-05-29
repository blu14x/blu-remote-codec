import csv
import tempfile
import traceback
from abc import ABC, abstractmethod
from inspect import getframeinfo, stack
from pathlib import Path
from types import SimpleNamespace
from typing import List
from typing import Union


class RemoteMapFileWriter:
    def __init__(self, remote_map: 'RemoteMap'):
        self.remote_map = remote_map

    def generate_file(self):
        remote_dir = Path(__file__).parents[2]
        manufacturer_maps_dir = remote_dir / 'Maps' / self.remote_map.manufacturer
        manufacturer_maps_dir.mkdir(parents=True, exist_ok=True)
        map_file = manufacturer_maps_dir / f'{self.remote_map.model}.remotemap'

        try:
            map_file_content = map_file.open('r').read()
        except FileNotFoundError:
            map_file_content = None

        try:
            with tempfile.NamedTemporaryFile('w', delete=False) as file:
                tmp_file = Path(file.name)
                writer = csv.writer(file, quotechar='\'', delimiter='\t', lineterminator='\n')

                writer.writerows(self.remote_map._write_rows)
                writer.writerows([(), ()])

                for scope in self.remote_map.scopes:
                    writer.writerows([(), (), ()])
                    writer.writerows(scope._write_rows)

                    writer.writerows([()])
                    for group in scope.groups:
                        writer.writerows(group._write_rows)

                    writer.writerows([(), ()])
                    for mapping in scope.mappings:
                        writer.writerows(mapping._write_rows)

            tmp_file_content = tmp_file.open('r').read()
            if tmp_file_content != map_file_content:
                print(f'Updated {self.remote_map.model}.remotemap')
                with map_file.open('w') as file:
                    file.write(tmp_file_content)

        except Exception as e:
            print(f'Could not generate {self.remote_map.model}.remotemap: ', traceback.format_exc(2))

        finally:
            tmp_file.unlink(missing_ok=True)


class FileWriterEntry(ABC):
    @abstractmethod
    def _write_rows(self):
        pass


class RemoteMap(FileWriterEntry):
    def __init__(self, manufacturer: str, model: str, file_format_version: str = None, map_version: str = None):
        self.manufacturer = manufacturer
        self.model = model
        self.file_format_version = file_format_version or '1.0.0'
        self.map_version = map_version or '1.0.0'

        self.scopes = []

        self._script_file_name = Path(getframeinfo(stack()[1][0]).filename).name

    def scope(self, *args, **kwargs):
        scope = Scope(*args, **kwargs)
        self.scopes.append(scope)
        return scope

    @property
    def _write_rows(self):
        return [
            ('Propellerhead Remote Mapping File',),
            ('File Format Version', self.file_format_version,),
            ('Control Surface Manufacturer', self.manufacturer,),
            ('Control Surface Model', self.model,),
            ('Map Version', self.map_version,),
            (),
            ('// This file a generated .remotemap!',),
            (f'// Adjustments should be made in "{self._script_file_name}".',),
        ]


class Scope(FileWriterEntry):
    def __init__(self, manufacturer: str, model: str):
        self.manufacturer = manufacturer
        self.model = model

        self.groups = []
        self.mappings = []

    def group(self, *args, **kwargs):
        group = Group(*args, **kwargs)
        self.groups.append(group)
        return group

    def map(self, *args, **kwargs):
        self.mappings.append(Mapping(*args, **kwargs))

    def div(self, *args, **kwargs):
        self.mappings.append(Divider(*args, **kwargs))

    @property
    def _write_rows(self):
        return [
            ('Scope', self.manufacturer, self.model),
        ]


class Group(FileWriterEntry):
    def __init__(self, name: str, values: List[str]):
        # prefix name and values with '_' (single underscore),
        # so there is no limitation for values as attributes

        self._name = name
        self._values = SimpleNamespace(
            **{value: f'{name}_{value}' for value in values}
        )

        for key, value in self._values.__dict__.items():
            setattr(self, f'set_{key}', f'{self._name}={value}')
            setattr(self, key, value)

    @property
    def _write_rows(self):
        return [
            ('Define Group', self._name, *self._values.__dict__.values(),),
        ]


class Divider(FileWriterEntry):
    enabled = True

    def __init__(self, height: int = 1):
        self.height = height

    @property
    def _write_rows(self):
        return [
            *[() for _ in range(self.height)],
        ] if self.enabled else []


class Mapping(FileWriterEntry):
    def __init__(self, c: str, r: str, k: str = None, s: int = None, m: str = None, g: Union[str, List[str]] = None):
        if g and not isinstance(g, list):
            g = [g]

        self.control_surface_item = c
        self.key = k
        self.remotable_item = r
        self.scale = s
        self.mode = m
        self.group_values = g or []

    @property
    def _write_rows(self):
        return [
            ('Map', self.control_surface_item, self.key, self.remotable_item, self.scale, self.mode, *self.group_values,),
        ]
