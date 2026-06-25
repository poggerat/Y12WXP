import main

def test_tokeniser():
    input = "hi"
    ans = main.tokeniser(input)
    assert(ans) == [104, 105]

def test_detokeniser():
    input = [104, 105]
    ans = main.detokeniser(input)
    assert(ans) == "hi"
