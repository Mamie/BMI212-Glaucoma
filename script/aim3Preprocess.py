# author: Sunil Pai (all code in this file)

# The purpose of this python code is to determine who took diabetic drugs
# Then, the drugs are labeled in long form if taken during the period between visits
# Because of the conditional nature, simple join/query operations were insufficient
# to encode the drug data in the matrix.

import whi
import copy

WHI_DIR = '/Users/sunilpai/Documents/WHI/'

whi_obj = extract_whi(WHI_DIR)

cohort = pd.read_csv(WHI_DIR + '../data/WHImerged.csv')
medication_history_44_table = whi_obj.data['f44_ctos_inv']()

antidiabetic_medication_dictionary = {
    271010.0: ['F44INSULIN'],
    271020.0: ['F44INSULIN'],
    271030.0: ['F44INSULIN'],
    271040.0: ['F44INSULIN'],
    272000.0: ['F44SULFONYLUREA'],
    272340.0: ['F44DPHENYLDERIV'],
    272500.0: ['F44BIGUANIDES'],
    272800.0: ['F44OTHERDIAB'],
    273000.0: ['F44OTHERDIAB'],
    273099.0: ['F44OTHERDIAB'],
    275000.0: ['F44OTHERDIAB'],
    276070.0: ['F44THIAZO'], 
    279970.0: ['F44BIGUANIDES', 'F44SULFONYLUREA'],
    279980.0: ['F44BIGUANIDES', 'F44THIAZO']
}

drug_data = {
    'F44INSULIN': [],
    'F44SULFONYLUREA': [],
    'F44DPHENYLDERIV': [],
    'F44BIGUANIDES': [],
    'F44OTHERDIAB': [],
    'F44THIAZO': []
}

cohort_ids = set(cohort['ID'])

for idx, code in enumerate(medication_history_44_table['TCCODE']):
    if code >= 270000 and code < 280000:
        for key in drug_data:
            if key in antidiabetic_medication_dictionary[code]:
                if medication_history_44_table['ID'][idx] in cohort_ids and medication_history_44_table['F44DAYS'][idx] > 0:
                    drug_data[key].append((
                        medication_history_44_table['ID'][idx],
                        int(round(medication_history_44_table['F44DAYS'][idx]/365)),
                        medication_history_44_table['MEDNDC'][idx],
                        medication_history_44_table['ADULTY'][idx],
                        code
                    ))

cohort_drug = copy.deepcopy(cohort)
cohort_drug = cohort_drug.assign(F44INSULIN=np.zeros(len(cohort_drug['ID'])))
cohort_drug = cohort_drug.assign(F44SULFONYLUREA=np.zeros(len(cohort_drug['ID'])))
cohort_drug = cohort_drug.assign(F44DPHENYLDERIV=np.zeros(len(cohort_drug['ID'])))
cohort_drug = cohort_drug.assign(F44BIGUANIDES=np.zeros(len(cohort_drug['ID'])))
cohort_drug = cohort_drug.assign(F44OTHERDIAB=np.zeros(len(cohort_drug['ID'])))
cohort_drug = cohort_drug.assign(F44THIAZO=np.zeros(len(cohort_drug['ID'])))
cohort_drug = cohort_drug.assign(F44INSULIN_MAXY=np.zeros(len(cohort_drug['ID'])))
cohort_drug = cohort_drug.assign(F44SULFONYLUREA_MAXY=np.zeros(len(cohort_drug['ID'])))
cohort_drug = cohort_drug.assign(F44DPHENYLDERIV_MAXY=np.zeros(len(cohort_drug['ID'])))
cohort_drug = cohort_drug.assign(F44BIGUANIDES_MAXY=np.zeros(len(cohort_drug['ID'])))
cohort_drug = cohort_drug.assign(F44OTHERDIAB_MAXY=np.zeros(len(cohort_drug['ID'])))
cohort_drug = cohort_drug.assign(F44THIAZO_MAXY=np.zeros(len(cohort_drug['ID'])))


for key in drug_data:
    print(key)
    for c_id, _, _, c_adulty, _ in drug_data[key]:
        cohort_drug[key][cohort_drug['ID']==c_id] = 1
        if cohort_drug[key+'_MAXY'][cohort_drug['ID']==c_id].iloc[0] < c_adulty:
            cohort_drug[key+'_MAXY'][cohort_drug['ID']==c_id] = c_adulty