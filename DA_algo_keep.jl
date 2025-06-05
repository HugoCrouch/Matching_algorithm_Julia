# DA algorithm with keep-comparison idea
function DA_keep(props, accs, prop_prefs, acc_prefs, acc_cap)
    prop_prefs_copy = deepcopy(prop_prefs)
    free_props = Set(props)
    acc_matches = Dict(a => [] for a in accs) #keep -> formal matching
    prop_matches = Dict(a => [] for a in props)
    acc_matches["outside"] = []
    prop_matches["outside"] = []
    acc_applylist = deepcopy(acc_matches)

    algo_lim = 5000
    count = 1

    while !isempty(free_props) && count < algo_lim
        for prop in free_props
            apply = first(prop_prefs_copy[prop])
            for j in acc_prefs[apply]
                if j[1] == prop
                    push!(acc_applylist[apply], j)
                end
            end
            prop_prefs_copy[prop] = setdiff(prop_prefs_copy[prop], [apply])
        end
        for acc in accs
            if acc_applylist[acc] !== acc_matches[acc]
                sort!(acc_applylist[acc], by = x -> x[2])

                k = min(acc_cap[acc], length(acc_applylist[acc]))
                acc_matches[acc] = acc_applylist[acc][1:k]

                if acc_matches[acc] == []
                    acc_matches[acc] = ("outside",1)
                end

                for kept in acc_matches[acc]
                    delete!(free_props, kept[1])
                end
                for rejected in acc_applylist[acc][k+1:end]
                    if isempty(prop_prefs_copy[rejected[1]])
                        push!(prop_matches["outside"], rejected[1])
                        delete!(free_props, rejected[1])
                    else
                        push!(free_props, rejected[1])
                    end
                end
            end
            acc_applylist[acc] = deepcopy(acc_matches[acc])
        end
        count += 1
        if count == algo_lim
            print("reached algo_lim")
        end
    end

    for acc in accs
        acc_matches[acc] = [k[1] for k in acc_matches[acc]]
        for i in acc_matches[acc]
            push!(prop_matches[i], acc)
        end
    end
    return prop_matches, acc_matches
end

proposers = ["A", "B", "C", "D", "E", "F"]
acceptors = ["X", "Y", "Z"]
proposer_prefs = Dict("A" => ["X", "Y", "Z"],
                      "B" => ["Y", "X", "Z"],
                      "C" => ["X", "Z", "Y"],
                      "D" => ["Z", "Y", "X"],
                      "E" => ["Y", "X"],
                      "F" => ["X", "Y"])
acceptor_prefs = Dict("X" => [("B",1), ("A",2), ("C",3), ("E",4), ("F",5)], 
                      "Y" => [("A",1), ("C",2), ("B",3), ("D",4), ("F",5), ("E",6)], 
                      "Z" => [("D",1), ("A",2), ("B",3), ("C",4)])
acceptor_capacity = Dict("X" => 2, "Y" => 2, "Z" => 2)

@time matches = DA(proposers, acceptors, proposer_prefs, acceptor_prefs, acceptor_capacity)
