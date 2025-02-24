import os
import sys
from datetime import datetime as dt

if __name__ == "__main__":
    print(dt.today(), "starting scrubbing")
    fastq_in_file = sys.argv[1]
    out_dir = sys.argv[2]
    out_name = os.path.basename(fastq_in_file)
    print("out:", out_name)
    with open(os.path.join(out_dir, out_name), "w") as out_file:
        with open (fastq_in_file, "r") as in_file:
            for line in in_file:
                if(line.startswith("+")):
                    out_file.write("+" + "\n")
                else:
                    out_file.write(line)
    
    print(dt.today(), "finished scrubbing")