import pandas as pd
import numpy as np
import os
import csv
import networkx as nx

FILE_NAME = "edges"
max_clique_size = 0
k = 5
all_clique_list = []
all_cliques = []
edge_list = []
new_edge_list = []
header = True
list_of_nodes = []

def find_max_node(table):
    max_int = -1;
    for i in table:
        if i[0] > max_int:
            max_int = i[0]
        if i[1] > max_int:
            max_int = i[1]
    return max_int

def abstracted_network(k_value, hasHeader):
    df = pd.read_csv(FILE_NAME + "\\" + FILE_NAME+'.csv')
    table = df.to_numpy()
    
    list_of_nodes = [-1 for i in range(find_max_node(table)+1)]
    #print(list_of_nodes)
    
    with open(FILE_NAME + "\\" + FILE_NAME + ".csv") as csv_file:
        csv_reader = csv.reader(csv_file, delimiter=',')
        if hasHeader:
            header = next(csv_reader)
        for row in csv_reader:
            row[0] = int(row[0])
            row[1] = int(row[1])
            edge_list.append(row)
    
    directory_to_use = FILE_NAME + "\\" + FILE_NAME + "_cliques_processed\\"+ FILE_NAME + "_min_clique" + str(k_value) + "\\"
    
    if k_value <= max_clique_size:
        for i in range(k_value - 2):
            df = pd.read_csv(directory_to_use + FILE_NAME+'_cliques_processed' + str(i+3) + '.csv', header=None)
            table = df.to_numpy()
            all_clique_list.append(table)
    else:
        print("K value too large")
    
    for i in all_clique_list:
        for j in i:
            #print(j)
            all_cliques.append(j)
        #print()
        
    #print(all_cliques)
    
    #print(all_cliques)
    
    counter = 0
    for i in all_cliques:
        for j in i:
            list_of_nodes[j] = counter
        counter+=1
    #print(list_of_nodes)
    
    for i in edge_list:
        edge = i
        if list_of_nodes[int(edge[0])] != -1:
            edge[0] = int(all_cliques[list_of_nodes[int(edge[0])]][0])
            #print(edge)
        if list_of_nodes[int(edge[1])] != -1:
            edge[1] = int(all_cliques[list_of_nodes[int(edge[1])]][0])
        if int(edge[0]) > int(edge[1]):
            edge.reverse()
        if edge not in new_edge_list and edge[0] != edge[1]:
            new_edge_list.append(edge)
    #sorted(new_edge_list)
    
    for i in new_edge_list:
        print(i)
        
    if not os.path.exists(FILE_NAME + "\\" + FILE_NAME+"_abstracted"):
        os.makedirs(FILE_NAME + "\\" + FILE_NAME+"_abstracted")
        
    with open(FILE_NAME + "\\" + FILE_NAME+"_abstracted\\" + FILE_NAME + "_abstracted_max_clique_" + str(k_value) + ".csv", 'w', newline = '') as f:
        write = csv.writer(f)
        write.writerows(new_edge_list)

def filteredNetwork(hasHeader):
    edges = pd.read_csv(FILE_NAME + "\\" + FILE_NAME+'.csv')
    print(edges)
    G = nx.from_pandas_edgelist(edges, source='fromPersonId', target='toPersonId')
    nodes = G.number_of_nodes()
    
    degree_centrality = nx.degree_centrality(G)
    #for i in degree_centrality:
        #print(degree_centrality[i])
    
    with open(FILE_NAME + "\\" + FILE_NAME + ".csv") as csv_file:
        csv_reader = csv.reader(csv_file, delimiter=',')
        if hasHeader:
            header = next(csv_reader)
        for row in csv_reader:
            row[0] = int(row[0])
            row[1] = int(row[1])
            edge_list.append(row)
    
    if not os.path.exists(FILE_NAME + "\\" + FILE_NAME+"_degree_centrality_network"):
        os.makedirs(FILE_NAME + "\\" + FILE_NAME+"_degree_centrality_network")
        
    new_edges = []
    for i in np.arange(0.025,0.25,0.025):
        new_edges = []
        for j in edge_list:
            if float(degree_centrality[j[0]]) > float(i) and float(degree_centrality[j[1]]) > float(i):
                new_edges.append(j)
        with open(FILE_NAME + "\\" + FILE_NAME+"_degree_centrality_network\\" + FILE_NAME + "_degree_centrality_" + str(i) + ".csv", 'w', newline = '') as f:
            write = csv.writer(f)
            write.writerows(new_edges)
            
    max_kcore = kcores = nx.k_core(G).edges()
    
    if not os.path.exists(FILE_NAME + "\\" + FILE_NAME+"_kcore_network"):
        os.makedirs(FILE_NAME + "\\" + FILE_NAME+"_kcore_network")
    
    counter = 0
    while True:
        kcores = nx.k_core(G, counter).edges()
        
        with open(FILE_NAME + "\\" + FILE_NAME+"_kcore_network\\" + FILE_NAME + "k-core_value" + str(counter) + ".csv", 'w', newline = '') as f:
            write = csv.writer(f)
            write.writerows(kcores)
        counter+=1
        if kcores == max_kcore:
            break
        
    # print(kcores)
    # for i in kcores:
    #     print(str(i[0]) + ", " + str(i[1]))
        
    # print(nodes)
    
    
if __name__ == "__main__" :
    method = "all"
    header = True
    
    max_clique_size = int(open(FILE_NAME + "\\" + FILE_NAME + "_max_clique_size.txt").readlines()[0])
    if method == "abstract" or "all":
        for i in range(max_clique_size - 2):
            abstracted_network(i + 3, header)
    if method == "filter" or "all":
        filteredNetwork(header)