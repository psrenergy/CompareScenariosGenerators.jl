function write_json(file::String, dict::AbstractDict, ident = 0)
    open(file, "w") do f
        return JSON.print(f, dict, ident)
    end
    return file
end

function calculate_hash_file(file::String)
    return bytes2hex(SHA.sha1(Mmap.mmap(file)))
end