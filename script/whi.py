# BMI 212 Glucoma 
#  Masood Malekghassemi

import collections
import os
import os.path
import re
import zipfile

import fuzzywuzzy
import pandas as pd


def open_zip(zipname, filename):
    """Return an opened file-like object for the path within the zip file."""
    with zipfile.ZipFile(zipname, 'r') as zip:
        return zip.open(filename)

class WhiDataFile(object):
    def __init__(self, zipfile, zipdatpath, zipsaspath):
        self.zipfile = zipfile
        self.zipdatpath = zipdatpath
        self.zipsaspath = zipsaspath
        self.columns = self._read(nrows=1).columns
        
        # extract column descriptions
        rough_matches = {}
        self.column_descs = {}
        with open_zip(self.zipfile, self.zipsaspath) as sasfile:
            for line in sasfile:
                line = line.decode('latin1')
                rough_match = re.match(r'\s*(.+)\s*=\s*(.+)', line)
                if rough_match is not None:
                    rough_matches[rough_match.group(1)] = rough_match.group(2)
        for column in self.columns:
            self.column_descs[column] = rough_matches[column] if column in rough_matches else None
        self.data = None
    def __call__(self):
        if self.data is None:
            self.data = self._read()
        return self.data
    def _read(self, **kwargs):
        return pd.read_csv(open_zip(self.zipfile, self.zipdatpath), '\t', encoding='latin1', **kwargs)
    def __getitem__(self, *args, **kwargs):
        return self().__getitem__(*args, **kwargs)
    def __getattr__(self, name):
        return self().__getattr__(name)

class WhiDataDir(object):
    def __init__(self, root_dir):
        self.root_dir = root_dir
        self.data = {}
        self.all_columns = None
        self.desc_postings = collections.defaultdict(list)
        self.data_paths = {}
        
    def _index(self):
        self.all_columns = collections.defaultdict(list)
        for name, dat in self.data.items():
            for column in set(dat.columns):
                self.all_columns[column].append(name)
            for column, desc in dat.column_descs.items():
                if desc is not None:
                    for token in desc.split():
                        self.desc_postings[token].append((name, column))
        self.all_columns = dict(self.all_columns)
        
    def search_columns(self, colname, limit=5):
        from fuzzywuzzy import process
        extracted = process.extract(colname, self.all_columns.keys(), limit=limit)
        return [x[0] for x in extracted]
    
    def search_column_descs(self, needle, limit=5):
        from fuzzywuzzy import process
        extracted = process.extract(needle, self.desc_postings.keys(), limit=limit)
        result = {}
        for x in extracted:
            for posting in self.desc_postings[x[0]]:
                data = self.data[posting[0]]
                desc = data.column_descs[posting[1]]
                result[x[0], posting[0]] = (posting[1], desc)
        return result

    def get_ids_for_variable(self, variable_name, dataset=None):
        if variable_name in self.all_columns:
            if dataset==None:
                dataset = self.all_columns[variable_name][0]
            table = self.data[dataset]()
            return set([ID for ID in table['ID'] * table[variable_name] if ID > 0])
        else:
            return set()        
    
    def get_population_size_for_indicator_variables(self, indicator_variables):
        return len(
            set.intersection(*[
                self.get_ids_for_variable(indicator_variable)
                for indicator_variable in indicator_variables
            ])
        )
    
    def get_followup_data(self, min_idx=0, max_idx=2):
        followup_tables = []
        for dataset_name in FOLLOWUP_DATASET_NAMES:
            followup_tables.append(self.data[dataset_name]())
        followup_table = followup_tables[min_idx]
        for t in followup_tables[min_idx+1:max_idx]:
            followup_table = followup_table.merge(t, on='ID')
        return followup_table
    
    def get_medical_history_data(self, form_number=30):
        if 'f{}_ctos_inv'.format(form_number) in self.data:
            return self.data['f{}_ctos_inv'.format(form_number)]()
        return None
    
def extract_whi(root):
    """Extract WHI data from the given directory."""
    whi = WhiDataDir(root)
    for dirname, subdirs, files in os.walk(root):
        for file in files:
            filename, fileext = os.path.splitext(file)
            if fileext == '.zip':
                zipfile = os.path.join(dirname, file)
                zipdatpath = filename + '.dat'
                zipsaspath = filename + '.sas'
                data_file = WhiDataFile(zipfile, zipdatpath, zipsaspath)
                whi.data[filename] = data_file
                whi.data_paths[zipfile + '::' + zipdatpath] = data_file
    whi._index()
    return whi

def merge_data(whi, form_var_names, on='ID'):
    """
    Example: ```
        merge_data(whi, [('outc_self_ctos_inv', 'F33ALZHEIMERS'), ('outc_self_ctos_inv', 'F33PARKINSONS')])
    ```
    Args:
        form_var_names: list[tuple[form-name, var-name]]
    """
    
    form_var_names = iter(form_var_names)
    form, var = next(form_var_names)
    tab = whi.data[form]()[['ID', var]]
    for form, var in form_var_names:
        next_tab = whi.data[form]()[['ID', var]]
        tab = pd.merge(tab, next_tab, on='ID')
    return tab
