import matplotlib
import matplotlib.pyplot as plt
import numpy as np
import csv

benches = ['add20', 'amazon', 'bomhof_1', 'bomhof_2', 'bomhof_3', 'google', 'hamm', 'human', 'roadnet', 'simucad_dac', 'simucad_ram2k', 'soc', 'stanford', 'wiki']
sizes = [64]

SMALL_SIZE = 8
MEDIUM_SIZE = 10
BIGGER_SIZE = 12

plt.rc('font', family='serif', size=10)          # controls default text sizes

matplotlib.rcParams['pdf.fonttype'] = 42
matplotlib.rcParams['ps.fonttype'] = 42

barwidth = 5

for size in sizes:

    plot_reqs = []
    plot_reqs.append({'topo' : 'fc_BFT0', 'bars' : [], 'barlabel' : 'BFT0', 'styling' : {'c' : '#BB7777', 'marker' : 'o', 'label' : 'BFT0\nAr.=2'}})
    plot_reqs.append({'topo' : 'fc_BFT1', 'bars' : [], 'barlabel' : 'BFT1', 'styling' : {'c' : '#BB5555', 'marker' : 'v', 'label' : 'BFT1\nAr.=2'}})
    plot_reqs.append({'topo' : 'fc_BFT2', 'bars' : [], 'barlabel' : 'BFT2', 'styling' : {'c' : '#BB3333', 'marker' : 's', 'label' : 'BFT2\nAr.=2'}})
    plot_reqs.append({'topo' : 'fc_BFT3', 'bars' : [], 'barlabel' : 'BFT3', 'styling' : {'c' : '#BB1111', 'marker' : 'D', 'label' : 'BFT3\nAr.=2'}})
    plot_reqs.append({'topo' : 'fc4_BFT0', 'bars' : [], 'barlabel' : 'BFT0', 'styling' : {'c' : '#77BB77', 'marker' : 'o', 'label' : 'BFT0\nAr.=4'}})
    plot_reqs.append({'topo' : 'fc4_BFT1', 'bars' : [], 'barlabel' : 'BFT1', 'styling' : {'c' : '#55BB55', 'marker' : 'v', 'label' : 'BFT1\nAr.=4'}})
    plot_reqs.append({'topo' : 'fc4_BFT2', 'bars' : [], 'barlabel' : 'BFT2', 'styling' : {'c' : '#33BB33', 'marker' : 's', 'label' : 'BFT2\nAr.=4'}})
    plot_reqs.append({'topo' : 'fc4_BFT3', 'bars' : [], 'barlabel' : 'BFT3', 'styling' : {'c' : '#11BB11', 'marker' : 'D', 'label' : 'BFT3\nAr.=4'}})

    fig, ax = plt.subplots(figsize=(3.4, 8))

    for bench in benches:
        topo_sels = ['fc{}_BFT{}'.format(a, b) for a in ['4', ''] for b in [str(i) for i in range(4)]]
        topo_sels.append('CMU')
        print(bench)

        with open('../results/perf/perf_sweep.csv', mode='r') as csv_perf_file:
            perf_rows = [row for row in csv.DictReader(csv_perf_file) if row['topo'] in topo_sels \
                                                                    and int(row['rate']) == 100 \
                                                                    and row['pat'] == bench and int(row['n']) == size ]

        with open('../results/hw_mapping/area_sweep.csv', mode='r') as csv_area_file:
            area_rows = [row for row in csv.DictReader(csv_area_file) if row['topo'] in topo_sels and int(row['n']) == size ]

        with open('../results/hw_mapping/freq_sweep.csv', mode='r') as csv_freq_file:
            freq_rows = [row for row in csv.DictReader(csv_freq_file) if row['topo'] in topo_sels and int(row['n']) == size ]                                                       

        data_dict = {(row['topo'], int(row['n'])) : {'power' : {10: 0, 20: 0, 30: 0, 40: 0, 50: 0, 100: 0},} for row in perf_rows}
        for row in freq_rows:
            entry = data_dict[(row['topo'], int(row['n']))]
            entry['freq'] = 1000.0/(float(row['cp']))

        for row in perf_rows:
            entry = data_dict[(row['topo'], int(row['n']))]
            entry['packets'] = int(row['sent'])
            entry['cycles'] = int(row['time_taken'])
            entry['tput'] = (entry['packets'] * entry['freq']) / (1000 * entry['cycles'])
            entry['ntput'] = entry['packets'] / entry['cycles']
            entry['wlat'] = (int(row['worst_total_latency']) / (entry['freq']))
            entry['nwlat'] = int(row['worst_total_latency'])

        for row in area_rows:
            entry = data_dict[(row['topo'], int(row['n']))]
            entry['luts'] = int(row['luts'])
            entry['qual'] = 1000*entry['tput']/entry['luts']

        ## Plot tput

        entry = data_dict[('fc_BFT0',size)]
        norm_ratio = entry['tput']/entry['luts']
        
        for req in plot_reqs:
            for key, entry in sorted(list(data_dict.items())):
                topo, n = key
                if (topo == req['topo']):
                    req['bars'].append(entry['tput']/(entry['luts']*norm_ratio))

    y_pos = np.arange(len(benches))
    for i, req in enumerate(plot_reqs):
        req_y_pos = [(10 * y + i) * 1.1 * barwidth for y in y_pos]
        ax.barh(req_y_pos, req['bars'], color=req['styling']['c'],height=barwidth, label=req['styling']['label'])

    ax.set_yticks([(10 * y + len(plot_reqs)/2) * 1.1 * barwidth for y in y_pos])
    ax.set_yticklabels(benches,rotation=30)
    plt.legend(loc='lower right')

    fig.savefig("ratios_" + str(size) + ".pdf", bbox_inches='tight')
    plt.close('all')
