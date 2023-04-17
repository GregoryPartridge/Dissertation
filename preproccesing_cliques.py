import pandas as pd
import numpy as np
import csv
import os

FILE_NAME = "inf-euroroad"
max_int = -1;
node_in_clique = []
cliques = []
max_clique_size = 0
current_clique_size = 0
edges_per_node = []
betweenness_values = []
closeness_values = []
max_int = -1;

def find_max_node(table):
    max_int = -1;
    for i in table:
        if i[0] > max_int:
            max_int = i[0]
        if i[1] > max_int:
            max_int = i[1]
    for i in range((max_int + 1)):
        node_in_clique.append(False)
    return max_int

def find_max_clique():
    x = 3;
    finished = False

    while(not finished):
        folder = FILE_NAME + "\\" + FILE_NAME + "_cliques"
        toLookFor = FILE_NAME + "_cliques" + str(x) + ".csv"
        if os.path.exists(folder + "\\" + toLookFor):
            x+=1
        else:
            finished = True
    return x

def setup():
    x = 3;
    finished = False

    while(x < current_clique_size + 1):
        folder = FILE_NAME + "\\" + FILE_NAME + "_cliques"
        toLookFor = FILE_NAME + "_cliques" + str(x) + ".csv"
        if os.path.exists(folder + "\\" + toLookFor):
            with open(folder + "\\" + toLookFor) as csv_file:
                #clique = pd.read_csv(folder + "\\" + toLookFor, header=None)
                csv_reader = csv.reader(csv_file, delimiter=',')
                clique = []
                for row in csv_reader:
                    toAppend = []
                    for i in range(x):
                        toAppend.append(int(row[i]))
                    clique.append(toAppend)
            cliques.append(clique)
        else:
            finished = True
        x+=1
    return x
    
def removeCliquesWithNodesAlreadyUsed():
    
    x = current_clique_size
    
    for i in cliques:
        
        #Create list which tracks whether clique has used nodes
        already_in_clique = []
        for j in i:
            already_in_clique.append(False)
            
        # print(len(i))
        # print(len(already_in_clique))
            
        #Check if already used
        y = 0
        for j in i:
            for k in range(x):
                if node_in_clique[j[k]]:
                    already_in_clique[y] = True
            y+=1
        
        #Remove Cliques
        for j in range(len(i)-1,-1,-1):
            if already_in_clique[j]:
                i.pop(j)
        
        #Mark already hit nodes
        for j in i:
            for k in range(x):
                node_in_clique[j[k]] = True
        
        # print(node_in_clique)
        x-=1
        
def remove_cliques_that_share_nodes():
    x = current_clique_size
    for i in cliques:
        to_delete = []
        for z in range(len(i)):
            to_delete.append(False)
        j_int = 0
        for j in i:
            k_int = 0
            for k in i:
                if j != k:
                    if common_member(j, k) and j_int > k_int:
                        j_tally = 0
                        k_tally = 0
                        for l in range(x):
                            # print(str(j[l]) + ", " + str(k[l]))
                            # print(str(edges_per_node[j[l]]) + ", " + str(edges_per_node[k[l]]))
                            j_tally += edges_per_node[j[l]]
                            k_tally += edges_per_node[k[l]]
                        if j_tally > k_tally:
                            to_delete[j_int] = True
                        else:
                            to_delete[k_int] = True
                k_int+=1
            j_int+=1
        x-=1
        for j in range(len(i)-1,-1,-1):
            if to_delete[j]:
                #print(i[j])
                i.pop(j)
                
def remove_cliques_that_share_nodes_betweeness_centrality():
    x = current_clique_size
    centrality = pd.read_csv(FILE_NAME + "\\" + FILE_NAME + "_node_betweenness_centrality.csv")
    #print(centrality)
    for i in betweenness_cliques:
        to_delete = []
        for z in range(len(i)):
            to_delete.append(False)
        j_int = 0
        for j in i:
            k_int = 0
            for k in i:
                if j != k:
                    if common_member(j, k) and j_int > k_int:
                        j_tally = 0.0
                        k_tally = 0.0
                        for l in range(x):
                            # print(str(j[l]) + ", " + str(k[l]))
                            # print(str(edges_per_node[j[l]]) + ", " + str(edges_per_node[k[l]]))
                            j_tally += betweenness_values[j[l]]
                            k_tally += betweenness_values[k[l]]
                        if j_tally[0] > k_tally[0]:
                            to_delete[j_int] = True
                        else:
                            to_delete[k_int] = True
                k_int+=1
            j_int+=1
        x-=1
        for j in range(len(i)-1,-1,-1):
            if to_delete[j]:
                #print(i[j])
                i.pop(j)
                
def remove_cliques_that_share_nodes_closeness_centrality():
    x = current_clique_size
    centrality = pd.read_csv(FILE_NAME + "\\" + FILE_NAME + "_node_closeness_centrality.csv")
    #print(centrality)
    for i in closeness_cliques:
        to_delete = []
        for z in range(len(i)):
            to_delete.append(False)
        j_int = 0
        for j in i:
            k_int = 0
            for k in i:
                if j != k:
                    if common_member(j, k) and j_int > k_int:
                        j_tally = 0.0
                        k_tally = 0.0
                        for l in range(x):
                            # print(str(j[l]) + ", " + str(k[l]))
                            # print(str(edges_per_node[j[l]]) + ", " + str(edges_per_node[k[l]]))
                            j_tally += closeness_values[j[l]]
                            k_tally += closeness_values[k[l]]
                        if j_tally[0] > k_tally[0]:
                            to_delete[j_int] = True
                        else:
                            to_delete[k_int] = True
                k_int+=1
            j_int+=1
        x-=1
        for j in range(len(i)-1,-1,-1):
            if to_delete[j]:
                #print(i[j])
                i.pop(j)
                            
def save_cliques(links):
    x = current_clique_size
    for i in links:
        if not os.path.exists(FILE_NAME + "\\" + FILE_NAME+"_cliques_processed"+"\\" + FILE_NAME + "_min_clique" + str(current_clique_size)):
            os.makedirs(FILE_NAME + "\\" + FILE_NAME+"_cliques_processed"+"\\" + FILE_NAME + "_min_clique" + str(current_clique_size))
        #print(i)
        proccesed_file_name = FILE_NAME + "\\" + FILE_NAME + "_cliques_processed"+"\\" + FILE_NAME + "_min_clique" + str(current_clique_size) + "\\" + FILE_NAME + "_cliques_processed"+str(x)+".csv"
        with open(proccesed_file_name, 'w', newline='') as f:
            write = csv.writer(f)
            write.writerows(i)
        x-=1

def save_cliques_betweenness_centrality(links):
    x = current_clique_size
    for i in links:
        if not os.path.exists(FILE_NAME + "\\" + FILE_NAME+"_cliques_processed"+"\\" + FILE_NAME + "_min_clique" + str(current_clique_size) + "_betweenness_centrality"):
            os.makedirs(FILE_NAME + "\\" + FILE_NAME+"_cliques_processed"+"\\" + FILE_NAME + "_min_clique" + str(current_clique_size)+ "_betweenness_centrality")
        #print(i)
        proccesed_file_name = FILE_NAME + "\\" + FILE_NAME + "_cliques_processed"+"\\" + FILE_NAME + "_min_clique" + str(current_clique_size) + "_betweenness_centrality" + "\\" + FILE_NAME + "_cliques_processed"+str(x)+".csv"
        with open(proccesed_file_name, 'w', newline='') as f:
            write = csv.writer(f)
            write.writerows(i)
        x-=1
        
def save_cliques_closeness_centrality(links):
    x = current_clique_size
    for i in links:
        if not os.path.exists(FILE_NAME + "\\" + FILE_NAME+"_cliques_processed"+"\\" + FILE_NAME + "_min_clique" + str(current_clique_size) + "_closeness_centrality"):
            os.makedirs(FILE_NAME + "\\" + FILE_NAME+"_cliques_processed"+"\\" + FILE_NAME + "_min_clique" + str(current_clique_size)+ "_closeness_centrality")
        #print(i)
        proccesed_file_name = FILE_NAME + "\\" + FILE_NAME + "_cliques_processed"+"\\" + FILE_NAME + "_min_clique" + str(current_clique_size) + "_closeness_centrality" + "\\" + FILE_NAME + "_cliques_processed"+str(x)+".csv"
        with open(proccesed_file_name, 'w', newline='') as f:
            write = csv.writer(f)
            write.writerows(i)
        x-=1

def common_member(a, b):
    a_set = set(a)
    b_set = set(b)
    if (a_set & b_set):
        return True
    else:
        return False

def get_node_links():
    nodes = []
    for i in range(max_int + 1):
        nodes.append(0)
    df = pd.read_csv(FILE_NAME + "\\" + FILE_NAME+'.csv')
    table = df.to_numpy()
    for i in table:
        nodes[i[0]]+=1
        nodes[i[1]]+=1
    x = 0;
    return nodes

def get_betwenness_centralities():
    nodes = []
    nodes.append(0.1)
    df = pd.read_csv(FILE_NAME + "\\" + FILE_NAME+'_node_betweenness_centrality.csv')
    table = df.to_numpy()
    x = 1
    for i in table:
        nodes.append(i[0])
        i+=1
    return nodes
   
def get_closeness_centralities():
    nodes = []
    nodes.append(0.1)
    df = pd.read_csv(FILE_NAME + "\\" + FILE_NAME+'_node_closeness_centrality.csv')
    table = df.to_numpy()
    x = 1
    for i in table:
        nodes.append(i[0])
        i+=1
    return nodes
     
def print_list(list):
    for i in list:
        for j in i:
            print(j)
    print()
    
if __name__ == "__main__" :
    max_clique_size = find_max_clique() - 1
    with open(FILE_NAME + "\\" + FILE_NAME + '_max_clique_size.txt', 'w') as f:
            f.write(str(max_clique_size))
    
    for i in range(1,max_clique_size):
        max_int = -1;
        node_in_clique = []
        cliques = []
        max_clique_size = 0
        current_clique_size = 0
        edges_per_node = []
        betweenness_values = []
        closeness_values = []
        max_int = -1;
    
        df = pd.read_csv(FILE_NAME + "\\" + FILE_NAME+'.csv')
        table = df.to_numpy()

        if not os.path.exists(FILE_NAME + "\\" + FILE_NAME+"_cliques_processed"):
            os.makedirs(FILE_NAME + "\\" + FILE_NAME+"_cliques_processed")
            
        max_clique_size = find_max_clique() - i
        current_clique_size = max_clique_size
        setup()
        max_int = find_max_node(table)
        
        edges_per_node = get_node_links()
        betweenness_values = get_betwenness_centralities()
        closeness_values = get_closeness_centralities()
        
        cliques.sort(reverse=True)
        #print_list(cliques)
        betweenness_cliques = cliques
        closeness_cliques = cliques        
        
        removeCliquesWithNodesAlreadyUsed()
        
        #print_list(cliques)
        remove_cliques_that_share_nodes()
        save_cliques(cliques)
        remove_cliques_that_share_nodes_betweeness_centrality()
        save_cliques_betweenness_centrality(betweenness_cliques)
        remove_cliques_that_share_nodes_closeness_centrality()
        save_cliques_closeness_centrality(closeness_cliques)