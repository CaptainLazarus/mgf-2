let lcs_array s1 s2 =
  let m = String.length s1 in
  let n = String.length s2 in
  let dp = Array.make_matrix (m + 1) (n + 1) (0, []) in

  (* TODO: Fill the table *)
  for i = 1 to m do
    for j = 1 to n do
      let x, s = dp.(i - 1).(j - 1) in
      dp.(i).(j) <-
        (if s1.[i - 1] = s2.[j - 1] then (x + 1, s1.[i - 1] :: s)
         else
           let x, _ = dp.(i - 1).(j) in
           let y, _ = dp.(i).(j - 1) in
           if x > y then dp.(i - 1).(j) else dp.(i).(j - 1))
    done
  done;

  dp.(m).(n)

let lcs_memo s1 s2 =
  let m = String.length s1 in
  let n = String.length s2 in
  let cache = Hashtbl.create 100 in

  let rec solve i j =
    if Hashtbl.mem cache (i, j) then Hashtbl.find cache (i, j)
    else
      let result =
        if i >= m || j >= n then (0, [])
        else if s1.[i] = s2.[j] then
          let x, s = solve (i + 1) (j + 1) in
          (x + 1, s1.[i] :: s)
        else
          let down = solve (i + 1) j in
          let right = solve i (j + 1) in
          if fst right > fst down then right else down
        (* TODO: Check if (i,j) in cache *)
        (* TODO: if yes, return cached value *)
        (* TODO: if no, compute: *)
        (*   - base case: i >= m || j >= n *)
        (*   - if s1.[i] = s2.[j] then ... *)
        (*   - else ... *)
      in
      Hashtbl.add cache (i, j) result;
      result
  in
  solve 0 0

let edit_distance_array s1 s2 =
  let m = String.length s1 in
  let n = String.length s2 in
  let dp = Array.make_matrix (m + 1) (n + 1) 0 in

  for i = 0 to m do
    dp.(i).(0) <- i
  done;

  for j = 0 to n do
    dp.(0).(j) <- j
  done;

  (* TODO: Fill the table *)
  for i = 1 to m do
    for j = 1 to n do
      if s1.[i - 1] = s2.[j - 1] then dp.(i).(j) <- dp.(i - 1).(j - 1)
      else
        dp.(i).(j) <-
          1 + min (min dp.(i - 1).(j) dp.(i).(j - 1)) dp.(i - 1).(j - 1)
    done
  done;

  dp.(m).(n)

let edit_distance_memo s1 s2 =
  let m = String.length s1 in
  let n = String.length s2 in
  let cache = Hashtbl.create 100 in

  let rec solve i j =
    if Hashtbl.mem cache (i, j) then Hashtbl.find cache (i, j)
    else
      let result =
        if i >= m then n - j
        else if j >= n then m - i
        else if s1.[i] = s2.[j] then solve (i + 1) (j + 1)
        else
          1
          + min
              (min (solve (i + 1) j) (solve i (j + 1)))
              (solve (i + 1) (j + 1))
      in
      Hashtbl.add cache (i, j) result;
      result
  in
  solve 0 0

(* LCS Test Cases *)
let lcs_tests =
  [
    (* (s1, s2, expected_length) *)
    ("ABCDGH", "AEDFHR", 3);
    (* ADH *)
    ("AGGTAB", "GXTXAYB", 4);
    (* GTAB *)
    ("", "", 0);
    (* both empty *)
    ("ABC", "", 0);
    (* one empty *)
    ("", "ABC", 0);
    (* one empty *)
    ("AAAA", "AAAA", 4);
    (* identical *)
    ("ABCDEF", "FEDCBA", 1);
    (* only one match *)
    ("programming", "gaming", 6);
    (* "gamin" or "grming" *)
    ("XMJYAUZ", "MZJAWXU", 4);
    (* MJAU *)
    ("abcdefg", "bcdgk", 4);
    (* bcdg *)
    ("nothingleft", "mnothingleft", 11);
    (* almost identical *)
    ("a", "a", 1);
    (* single char match *)
    ("a", "b", 0);
    (* single char no match *)
    ("abcd", "dcba", 1);
    (* reversed, only one *)
    ("BANANA", "ATANA", 4);
    (* AANA *)
  ]

(* Edit Distance Test Cases *)
let edit_tests =
  [
    (* (s1, s2, expected_distance) *)
    ("kitten", "sitting", 3);
    (* classic example *)
    ("Saturday", "Sunday", 3);
    (* classic example *)
    ("", "", 0);
    (* both empty *)
    ("abc", "", 3);
    (* delete all *)
    ("", "abc", 3);
    (* insert all *)
    ("abc", "abc", 0);
    (* identical *)
    ("horse", "ros", 3);
    (* delete h,e, replace r *)
    ("intention", "execution", 5);
    (* complex *)
    ("a", "b", 1);
    (* single replace *)
    ("a", "a", 0);
    (* single match *)
    ("ab", "ba", 2);
    (* swap = 2 ops *)
    ("cafe", "coffee", 3);
    (* insert o,f,e, replace a *)
    ("algorithm", "altruistic", 6);
    (* complex *)
    ("exponential", "polynomial", 6);
    (* complex *)
    ("ABCDEFG", "AZCED", 4);
    (* delete B,F,G, replace C *)
  ]

(* Test runner *)
let test_lcs lcs_fn name =
  Printf.printf "\nTesting %s:\n" name;
  List.iter
    (fun (s1, s2, expected) ->
      let len, _ = lcs_fn s1 s2 in
      if len = expected then
        Printf.printf "  ✓ lcs(\"%s\", \"%s\") = %d\n" s1 s2 len
      else
        Printf.printf "  ✗ lcs(\"%s\", \"%s\") = %d (expected %d)\n" s1 s2 len
          expected)
    lcs_tests

let test_edit_distance edit_fn name =
  Printf.printf "\nTesting %s:\n" name;
  List.iter
    (fun (s1, s2, expected) ->
      let dist = edit_fn s1 s2 in
      if dist = expected then
        Printf.printf "  ✓ edit(\"%s\", \"%s\") = %d\n" s1 s2 dist
      else
        Printf.printf "  ✗ edit(\"%s\", \"%s\") = %d (expected %d)\n" s1 s2 dist
          expected)
    edit_tests

(* Run all tests *)
let dp =
  test_lcs lcs_array "LCS Array";
  test_lcs lcs_memo "LCS Memo";
  test_edit_distance edit_distance_array "Edit Distance Array";
  test_edit_distance edit_distance_memo "Edit Distance Memo";
  print_endline "\n✅ All tests complete!"
