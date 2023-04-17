import pandas as pd
import numpy as np
import os
import networkx as nx  

FILE_NAME = "inf-euroroad"
finished = False

df = pd.read_csv(FILE_NAME + "\\" + FILE_NAME+'.csv')
table = df.to_numpy()

if not os.path.exists(FILE_NAME + "\\" + FILE_NAME+"_cliques"):
    os.makedirs(FILE_NAME + "\\" + FILE_NAME+"_cliques")

biggest_edge = -1
for i in table:
    if i[0] > biggest_edge:
        biggest_edge = i[0]
    if i[1] > biggest_edge:
        biggest_edge = i[1]
biggest_edge+=1

#print(biggest_edge)
 
graph = np.zeros((biggest_edge, biggest_edge));
store = [0]* biggest_edge;
d = [0] * biggest_edge;
 
# Function to check if the given set of vertices
# in store array is a clique or not
def is_clique(b) :
 
    # Run a loop for all the set of edges
    # for the select vertex
    for i in range(1, b) :
        for j in range(i + 1, b) :
 
            # If any edge is missing
            if (graph[store[i]][store[j]] == 0) :
                return False;
     
    return True;
 
# Function to print the clique
def save_cli(n) :
    to_append = []
    for i in range(1, n) :
        to_append.append(store[i]);
    list_of_cliques.append(to_append);
    finished = False
    
 
# Function to find all the cliques of size s
def findCliques(i, l, s) :
    # Check if any vertices from i+1 can be inserted
    for j in range( i + 1, n -(s - l) + 1) :
 
        # If the degree of the graph is sufficient
        if (d[j] >= s - 1) :
 
            # Add the vertex to store
            store[l] = j;
 
            # If the graph is not a clique of size k
            # then it cannot be a clique
            # by adding another edge
            if (is_clique(l + 1)) :
 
                # If the length of the clique is
                # still less than the desired size
                if (l < s) :
 
                    # Recursion to add vertices
                    findCliques(j, l + 1, s);
 
                # Size is met
                else :
                    save_cli(l + 1);
                    
def get_betweenness_centrality():
    edges = pd.read_csv(FILE_NAME + "\\" + FILE_NAME+'.csv')
    #print(edges)
    G = nx.from_pandas_edgelist(edges, source='fromPersonId', target='toPersonId')
    betweenness_centrality = nx.betweenness_centrality(G)
    #print(betweenness_centrality)
    to_save = pd.DataFrame([betweenness_centrality])
    to_save.T.to_csv(FILE_NAME + "\\" + FILE_NAME+"_node_betweenness_centrality.csv",index=False, header=False)
    
def get_closeness_centrality():
    edges = pd.read_csv(FILE_NAME + "\\" + FILE_NAME+'.csv')
    #print(edges)
    G = nx.from_pandas_edgelist(edges, source='fromPersonId', target='toPersonId')
    closeness_centrality = nx.closeness_centrality(G)
    #print(closeness_centrality)
    to_save = pd.DataFrame([closeness_centrality])
    to_save.T.to_csv(FILE_NAME + "\\" + FILE_NAME+"_node_closeness_centrality.csv",index=False, header=False)
 
# Driver code
if __name__ == "__main__" :
    
    get_betweenness_centrality()
    get_closeness_centrality()
    
    k = 3;
    while not finished:
        finished = True
        list_of_cliques = []
        edges = table
        size = len(edges);
        n = biggest_edge-1;
    
        for i in range(size) :
            graph[edges[i][0]][edges[i][1]] = 1;
            graph[edges[i][1]][edges[i][0]] = 1;
            d[edges[i][0]] += 1;
            d[edges[i][1]] += 1;
        
        findCliques(0, 1, k);
        if len(list_of_cliques) > 0:
            finished = False
        
        df = pd.DataFrame(list_of_cliques).astype('Int64')
        #print(df)

        if len(list_of_cliques) > 0:
            df.to_csv(FILE_NAME + "\\" + FILE_NAME+"_cliques\\"+FILE_NAME + "_cliques"+str(k)+".csv",index=False, header=False)
        k+=1