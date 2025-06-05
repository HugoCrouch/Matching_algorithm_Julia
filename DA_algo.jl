# multiple to multiple Deferred Acceptance Algorithm in Julia

function deferred_acceptance(props, accs, prop_prefs, acc_prefs, prop_cap, acc_cap)
    free_props = Set(props)
    acc_matches = Dict(a => [] for a in accs)
    prop_matches = Dict(a => [] for a in props)
    acc_matches["outside"] = []
    prop_matches["outside"] = []
    
    while !isempty(free_props) #continue until all proposers have been matched 
        rejection = 0
        prop = first(free_props)
        prop_pref_list = setdiff(prop_prefs[prop], prop_matches[prop])
        
        for acc in prop_pref_list
            acc_pref_list = acc_prefs[acc]
            cap = acc_cap[acc]
            if in(prop, acc_pref_list)
                if length(acc_matches[acc]) < cap
                    # acc is capable, match them
                    push!(acc_matches[acc], prop)
                    push!(prop_matches[prop], acc)
                    if length(prop_matches[prop]) == prop_cap[prop]
                        delete!(free_props, prop)
                    end
                    break
                else
                    worst_match = 1
                    for current_match in acc_matches[acc]
                        order = findfirst(==(current_match), acc_pref_list)
                        if order > worst_match
                            worst_match = order
                        end
                    end

                    if findfirst(==(prop), acc_pref_list) < worst_match
                        filter!(e -> e ≠ acc_pref_list[worst_match], acc_matches[acc])
                        push!(acc_matches[acc], prop)
                        push!(prop_matches[prop], acc)
                        if length(prop_matches[prop]) == prop_cap[prop]
                            delete!(free_props, prop)
                        end
                        prop_matches[acc_pref_list[worst_match]] = setdiff(prop_matches[acc_pref_list[worst_match]], [acc])
                        if !(acc_pref_list[worst_match] in free_props)
                            push!(free_props, acc_pref_list[worst_match])
                        end
                        break
                    end
                end
            end
            print("prop: ", prop, " x acc:", acc, "\n")
            rejection += 1
            if rejection == length(prop_pref_list)
                if isempty(prop_matches[prop])
                    push!(prop_matches["outside"], prop)
                end
                delete!(free_props, prop)
            end
        end
    end
    for acc in accs
        if isempty(acc_matches[acc])
            push!(acc_matches["outside"], acc)
        end
    end
    return prop_matches, acc_matches
end

# Example usage
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
proposer_capacity = Dict(s => 1 for s in proposers)

@time deferred_acceptance(proposers, acceptors, proposer_prefs, acceptor_prefs, proposer_capacity, acceptor_capacity)
println(matches)


