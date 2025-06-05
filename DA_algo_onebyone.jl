#DA algorithm with one-by-one proposer accepting idea
function DA_onebyone(props, accs, prop_prefs, acc_prefs, acc_cap)
    prop_prefs_copy = deepcopy(prop_prefs)
    free_props = Set(props)
    acc_matches = Dict(a => [] for a in accs)
    prop_matches = Dict(a => [] for a in props)
    acc_matches["outside"] = []
    prop_matches["outside"] = []
    algo_lim = 5000
    count = 1

    while !isempty(free_props) && count < algo_lim
        for prop in free_props
            apply = first(prop_prefs_copy[prop])
            if in(prop, acc_prefs[apply])
                if length(acc_matches[apply]) < acc_cap[apply]
                    push!(acc_matches[apply], prop)
                    push!(prop_matches[prop], apply)
                    delete!(free_props, prop)
                else
                    worst_match = 1
                    for current_match in acc_matches[apply]
                        order = findfirst(==(current_match), acc_prefs[apply])
                        if order > worst_match
                            worst_match = order
                        end
                    end
                    if findfirst(==(prop), acc_prefs[apply]) < worst_match
                        rejected = acc_prefs[apply][worst_match]
                        #if acceptor prefers the new prop
                        filter!(e -> e ≠ rejected, acc_matches[apply])
                        push!(acc_matches[apply], prop)
                        push!(prop_matches[prop], apply)
                        delete!(free_props, prop)
                        prop_matches[rejected] = []
                        if isempty(prop_prefs_copy[rejected])
                            push!(prop_matches["outside"], prop)
                        else
                            push!(free_props, rejected)
                        end
                    end
                end
            end
            prop_prefs_copy[prop] = setdiff(prop_prefs_copy[prop], [apply])
            if isempty(prop_prefs_copy[prop]) && isempty(prop_matches[prop])
                push!(prop_matches["outside"], prop)
                delete!(free_props, prop)
            end
        end
        count += 1
        if count == algo_lim
            print("reached algo_lim")
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
acceptor_prefs = Dict("X" => ["B", "A", "C", "E", "F"], 
                      "Y" => ["A", "C", "B", "D", "F", "E"], 
                      "Z" => ["D", "A", "B", "C"])
acceptor_capacity = Dict("X" => 2, "Y" => 2, "Z" => 2)

@time matches = DA(proposers, acceptors, proposer_prefs, acceptor_prefs, acceptor_capacity)
