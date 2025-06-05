# DA algorithm with keep-comparison idea
function DA_keep(props, accs, prop_prefs, acc_prefs, acc_cap)
    prop_prefs_copy = deepcopy(prop_prefs) # Dictionary for each acceptor
    free_props = Set(props) 
    acc_matches = Dict(a => [] for a in accs)
    prop_matches = Dict(a => [] for a in props)
    acc_matches["outside"] = []
    prop_matches["outside"] = []
    acc_applylist = deepcopy(acc_matches) # Dictionary for each acceptor

    algo_lim = 5000 # limit in case of too long iteration
    count = 1

    while !isempty(free_props) && count < algo_lim # continue until everybody gets matched
        for prop in free_props
            flag = false # to check prop not accepted to applylist
            apply = first(prop_prefs_copy[prop]) # most prefarable one at this time
            for j in acc_prefs[apply[1]]
                if j[1] == prop # check individual rationality
                    push!(acc_applylist[apply[1]], j)
                    flag = true
                end
            end
            prop_prefs_copy[prop] = setdiff(prop_prefs_copy[prop], [apply]) # delete the acceptor from the proposer's preference list(copy)
            if flag == false
                if isempty(prop_prefs_copy[prop])
                    push!(prop_matches["outside"], prop) # matches outside option
                    delete!(free_props, prop)
                end
            end
        end

        # acc_applylist is filled 
        for acc in accs
            if acc_applylist[acc] !== acc_matches[acc] # only if the kept proposers profile is different from the previous 
                sort!(acc_applylist[acc], by = x -> x[2])

                k = min(acc_cap[acc], length(acc_applylist[acc])) # not to exceed the capacity, also technically not to exceed the current matches
                acc_matches[acc] = acc_applylist[acc][1:k] #"keep"

                for kept in acc_matches[acc] # delete proposers from the free propser set
                    delete!(free_props, kept[1])
                end

                for rejected in acc_applylist[acc][k+1:end]
                    if isempty(prop_prefs_copy[rejected[1]])
                        push!(prop_matches["outside"], rejected[1]) # matches outside option
                        delete!(free_props, rejected[1])
                    else
                        push!(free_props, rejected[1]) # add the rejeted proposer to free proposer set
                    end
                end
            end
            acc_applylist[acc] = deepcopy(acc_matches[acc]) # only kept proposers remain
        end

        count += 1
        if count == algo_lim
            print("reached algo_lim")
        end
    end

    for acc in accs
        acc_matches[acc] = [k[1] for k in acc_matches[acc]]
        if acc_matches[acc] == []
            push!(acc_matches["outside"], acc) 
        end
        for i in acc_matches[acc]
            push!(prop_matches[i], acc)
        end
    end
    return prop_matches, acc_matches
end

proposers = ["A", "B", "C", "D", "E", "F"]
acceptors = ["X", "Y", "Z"]
proposer_prefs = Dict("A" => [("X",1), ("Y",2), ("Z",3)],
                      "B" => [("Y",1), ("X",2), ("Z",3)],
                      "C" => [("X",1), ("Z",2), ("Y",3)],
                      "D" => [("Z",1), ("Y",2), ("X",3)],
                      "E" => [("Y",), ("X",2)],
                      "F" => [("X",1), ("Y",2)])
acceptor_prefs = Dict("X" => [("B",1), ("A",2), ("C",3), ("E",4), ("F",5)], 
                      "Y" => [("A",1), ("C",2), ("B",3), ("D",4), ("F",5), ("E",6)], 
                      "Z" => [("D",1), ("A",2), ("B",3), ("C",4)])
acceptor_capacity = Dict("X" => 2, "Y" => 2, "Z" => 2)

@time matches = DA_keep(proposers, acceptors, proposer_prefs, acceptor_prefs, acceptor_capacity)
