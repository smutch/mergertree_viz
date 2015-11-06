from __future__ import print_function, division
import json
from collections import deque

import click
import numpy as np
import networkx as nx
from networkx.readwrite import json_graph
from tqdm import tqdm

from dragons import meraxes


PROPS = ("StellarMass", "Sfr", "Mvir", "Len", "ID", "Type", "GhostFlag")
tree = nx.Graph()


def walk(snap, ind, fp_ind, np_ind):
    global tree

    tree.add_node(ind, _snap=snap)
    first_ind = fp_ind[snap][ind]

    if first_ind > -1:
        walk(snap-1, first_ind, fp_ind, np_ind)
        tree.add_edge(ind, first_ind, weight=2)
        next_ind = np_ind[snap-1][first_ind]

        while next_ind > -1:
            walk(snap-1, next_ind, fp_ind, np_ind)
            tree.add_edge(ind, next_ind, weight=2)
            next_ind = np_ind[snap-1][next_ind]


def add_galaxy_to_node(node, galaxy):
    for p in PROPS:
        node[p] = galaxy[p]


@click.command()
@click.argument('fname', type=click.STRING)
@click.argument('snapshot', type=click.INT)
@click.argument('id', type=click.STRING)
def history_to_json(fname, snapshot, id):
    """Generate json version of merger history."""

    id = np.longlong(id)
    meraxes.set_little_h(fname)

    gals = meraxes.read_gals(fname, snapshot, props=PROPS, quiet=True)
    snaplist, _, _ = meraxes.read_snaplist(fname)

    # get the ind of our start galaxy
    ind = np.where(gals['ID'] == id)[0]
    print(ind)
    assert(type(ind) == int)

    # read in the walk indices
    fp_ind = deque()
    np_ind = deque()
    for snap in tqdm(snaplist, desc="Reading indices"):
        try:
            fp_ind.append(meraxes.read_firstprogenitor_indices(fname, snap))
        except:
            fp_ind.append([])
        try:
            np_ind.append(meraxes.read_nextprogenitor_indices(fname, snap))
        except:
            np_ind.append([])

    # generate the graph (populates global variable `tree`)
    walk(snapshot, ind, fp_ind, np_ind)

    # attach the galaxies to the graph
    for snap in tqdm(snaplist, desc="Generating graph"):
        try:
            gal = meraxes.read_gals(fname, snapshot=snap, quiet=True,
                                    props=PROPS)
        except IndexError:
            continue
        for ii in tree.nodes_iter():
            node = tree[ii]
            if node["_snap"] == snap:
                add_galaxy_to_node(node, gal[ii])

    # dump the tree to json
    data = json_graph.tree_data(tree, root=ind)
    fname_out = "tree_%09d.json" % id
    with open(fname_out, "wb") as fd:
        json.dump(data, fd)

    print("Conversion complete: %s" % fname_out)

if __name__ == "__main__":
    history_to_json()
