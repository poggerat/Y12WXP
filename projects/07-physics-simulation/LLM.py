from pathlib import Path

DATA = Path(__file__).resolve().parent.parent / "data" / "input.txt"
text = DATA.read_text(encoding="utf-8")

chars = sorted(set(text))

stoi = {ch: i for i, ch in enumerate(chars)}
itos = {i: ch for ch, i in stoi.items()}

def encode(s): 
    return [stoi[c] for c in s]
def decode(ids): 
    return "".join(itos[i] for i in ids)