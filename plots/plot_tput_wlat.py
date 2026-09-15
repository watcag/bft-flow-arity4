import matplotlib
import matplotlib.pyplot as plt
import numpy as np
import csv

benches = ['add20', 'amazon', 'bomhof_1', 'bomhof_2', 'bomhof_3', 'google', 'hamm', 'human', 'roadnet', 'simucad_dac', 'simucad_ram2k', 'soc', 'stanford', 'wiki']
sizes = [64]

SMALL_SIZE = 8
MEDIUM_SIZE = 10
BIGGER_SIZE = 12

plt.rc('text', usetex=True)
plt.rc('font', family='serif', size=BIGGER_SIZE)          # controls default text sizes

matplotlib.rcParams['pdf.fonttype'] = 42
matplotlib.rcParams['ps.fonttype'] = 42

for bench in benches:
    for size in sizes:
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

        plot_reqs = []
        plot_reqs.append({'topo' : 'fc_BFT0', 'barlabel' : 'BFT0\narity = 2', 'styling' : {'c' : 'r', 'marker' : 'o', 'label' : 'BFT0-Arity=2'}})
        plot_reqs.append({'topo' : 'fc_BFT1', 'barlabel' : 'BFT1', 'styling' : {'c' : 'r', 'marker' : 'v', 'label' : 'BFT1-Arity=2'}})
        plot_reqs.append({'topo' : 'fc_BFT2', 'barlabel' : 'BFT2', 'styling' : {'c' : 'r', 'marker' : 's', 'label' : 'BFT2-Arity=2'}})
        plot_reqs.append({'topo' : 'fc_BFT3', 'barlabel' : 'BFT3', 'styling' : {'c' : 'r', 'marker' : 'D', 'label' : 'BFT3-Arity=2'}})
        plot_reqs.append({'topo' : 'fc4_BFT0', 'barlabel' : 'BFT0\narity = 4', 'styling' : {'c' : 'g', 'marker' : 'o', 'label' : 'BFT0-Arity=4'}})
        plot_reqs.append({'topo' : 'fc4_BFT1', 'barlabel' : 'BFT1', 'styling' : {'c' : 'g', 'marker' : 'v', 'label' : 'BFT1-Arity=4'}})
        plot_reqs.append({'topo' : 'fc4_BFT2', 'barlabel' : 'BFT2', 'styling' : {'c' : 'g', 'marker' : 's', 'label' : 'BFT2-Arity=4'}})
        plot_reqs.append({'topo' : 'fc4_BFT3', 'barlabel' : 'BFT3', 'styling' : {'c' : 'g', 'marker' : 'D', 'label' : 'BFT3-Arity=4'}})
        plot_reqs.append({'topo' : 'CMU', 'barlabel' : 'CMU', 'styling' : {'c' : 'm', 'marker' : 'X', 'label' : 'CONNECT'}})

        ## Plot tput
        fig = plt.figure()
        ax = fig.add_subplot(1, 1, 1)
        ax.set_axisbelow(True)
        plt.grid(True)
        ymax = 0
        for req in plot_reqs:
            x = []
            y = []
            for key, entry in sorted(list(data_dict.items())):
                topo, n = key
                if (topo == req['topo']):
                    x.append(entry['luts'])
                    y.append(entry['tput'])

            ax.scatter(x, y, s=100, **req['styling'])
            ymax = max(ymax, max(y))

        plt.xlabel("LUTs")
        plt.ylabel("Throughput (packets/ns)")
        ax.set_xlim(xmin=0)
        ax.set_ylim(ymin=0,ymax=1.1*ymax)

        fig.savefig(bench + "_cmp_tput_area_" + str(size) + ".pdf", bbox_inches='tight')

        ## Plot ntput
        fig = plt.figure()
        ax = fig.add_subplot(1, 1, 1)
        ax.set_axisbelow(True)
        plt.grid(True)
        ymax = 0
        for req in plot_reqs:
            x = []
            y = []
            for key, entry in sorted(list(data_dict.items())):
                topo, n = key
                if (topo == req['topo']):
                    x.append(entry['luts'])
                    y.append(entry['ntput'])

            ax.scatter(x, y, s=100, **req['styling'])
            ymax = max(ymax, max(y))

        ax.set_xlim(xmin=0)
        ax.set_ylim(ymin=0,ymax=1.1*ymax)
        plt.xlabel("LUTs")
        plt.ylabel("Throughput (packets/cycle)")

        fig.savefig(bench + "_cmp_ntput_area_" + str(size) + ".pdf", bbox_inches='tight')

        ## Plot worst case latency
        fig = plt.figure()
        ax = fig.add_subplot(1, 1, 1)
        ax.set_axisbelow(True)
        plt.grid(True)
        ymax = 0
        for req in plot_reqs:
            x = []
            y = []
            for key, entry in sorted(list(data_dict.items())):
                topo, n = key
                if (topo == req['topo']):
                    x.append(entry['luts'])
                    y.append(entry['wlat'])

            ax.scatter(x, y, s=100, **req['styling'])
            ymax = max(ymax, max(y))

        ax.set_xlim(xmin=0)
        ax.set_ylim(ymin=0,ymax=1.1*ymax)
        plt.xlabel("LUTs")
        plt.ylabel("Worst case latency (ns)")

        fig.savefig(bench + "_cmp_wlat_area_" + str(size) + ".pdf", bbox_inches='tight')

        ## Plot normalized (per cycle) worst case latency
        fig = plt.figure()
        ax = fig.add_subplot(1, 1, 1)
        ax.set_axisbelow(True)
        plt.grid(True)
        ymax = 0
        for req in plot_reqs:
            x = []
            y = []
            for key, entry in sorted(list(data_dict.items())):
                topo, n = key
                if (topo == req['topo']):
                    x.append(entry['luts'])
                    y.append(entry['nwlat'])

            ax.scatter(x, y, s=100, **req['styling'])
            ymax = max(ymax, max(y))

        ax.set_xlim(xmin=0)
        ax.set_ylim(ymin=0,ymax=1.1*ymax)
        plt.xlabel("LUTs")
        plt.ylabel("Worst case latency (Cycles)")

        fig.savefig(bench + "_cmp_nwlat_area_" + str(size) + ".pdf", bbox_inches='tight')

        plt.close('all')
