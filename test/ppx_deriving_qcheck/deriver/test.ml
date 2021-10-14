(** Module test for ppx_deriving_qcheck *)
open Ppxlib

(** Primitive types tests *)
let loc = Location.none

let f = Ppx_deriving_qcheck.derive_gen ~loc

let f' xs = List.map f xs |> List.concat

let extract stri =
  match stri.pstr_desc with Pstr_type (x, y) -> (x, y) | _ -> assert false

let extract' xs = List.map extract xs

let check_eq ~expected ~actual name =
  let f = Ppxlib.Pprintast.string_of_structure in
  Alcotest.(check string) name (f expected) (f actual)

let test_int () =
  let expected = [ [%stri let gen = QCheck.Gen.int] ] in

  let actual = f @@ extract [%stri type t = int] in

  check_eq ~expected ~actual "deriving int"

let test_float () =
  let expected = [ [%stri let gen = QCheck.Gen.float] ] in
  let actual = f @@ extract [%stri type t = float] in

  check_eq ~expected ~actual "deriving float"

let test_char () =
  let expected = [ [%stri let gen = QCheck.Gen.char] ] in
  let actual = f @@ extract [%stri type t = char] in

  check_eq ~expected ~actual "deriving char"

let test_string () =
  let expected = [ [%stri let gen = QCheck.Gen.string] ] in
  let actual = f @@ extract [%stri type t = string] in

  check_eq ~expected ~actual "deriving string"

let test_unit () =
  let expected = [ [%stri let gen = QCheck.Gen.unit] ] in
  let actual = f @@ extract [%stri type t = unit] in

  check_eq ~expected ~actual "deriving unit"

let test_bool () =
  let expected = [ [%stri let gen = QCheck.Gen.bool] ] in
  let actual = f @@ extract [%stri type t = bool] in

  check_eq ~expected ~actual "deriving bool"

let test_int32 () =
  let expected = [ [%stri let gen = QCheck.Gen.int32] ] in
  let actual = f @@ extract [%stri type t = int32] in

  check_eq ~expected ~actual "deriving int32"

let test_int32' () =
  let expected = [ [%stri let gen = QCheck.Gen.int32] ] in
  let actual = f @@ extract [%stri type t = Int32.t] in

  check_eq ~expected ~actual "deriving int32'"

let test_int64 () =
  let expected = [ [%stri let gen = QCheck.Gen.int64] ] in
  let actual = f @@ extract [%stri type t = int64] in

  check_eq ~expected ~actual "deriving int64"

let test_int64' () =
  let expected = [ [%stri let gen = QCheck.Gen.int64] ] in
  let actual = f @@ extract [%stri type t = Int64.t] in

  check_eq ~expected ~actual "deriving int64'"

(* let test_bytes () =
 *   let expected =
 *     [
 *       [%stri
 *         let gen =
 *           QCheck.map
 *             (fun n -> Bytes.create n)
 *             QCheck.(0 -- Sys.max_string_length)];
 *     ]
 *   in
 *   let actual = f @@ extract [%stri type t = Bytes.t ] in
 * 
 *   check_eq ~expected ~actual "deriving int64" *)

let test_tuple () =
  let actual =
    f'
    @@ extract'
         [
           [%stri type t = int * int];
           [%stri type t = int * int * int];
           [%stri type t = int * int * int * int];
           [%stri type t = int * int * int * int * int];
           [%stri type t = int * int * int * int * int * int];
         ]
  in
  let expected =
    [
      [%stri
        let gen =
          QCheck.Gen.map
            (fun (gen0, gen1) -> (gen0, gen1))
            (QCheck.Gen.pair QCheck.Gen.int QCheck.Gen.int)];
      [%stri
        let gen =
          QCheck.Gen.map
            (fun (gen0, gen1, gen2) -> (gen0, gen1, gen2))
            (QCheck.Gen.triple QCheck.Gen.int QCheck.Gen.int QCheck.Gen.int)];
      [%stri
        let gen =
          QCheck.Gen.map
            (fun (gen0, gen1, gen2, gen3) -> (gen0, gen1, gen2, gen3))
            (QCheck.Gen.quad
               QCheck.Gen.int
               QCheck.Gen.int
               QCheck.Gen.int
               QCheck.Gen.int)];
      [%stri
        let gen =
          QCheck.Gen.map
            (fun ((gen0, gen1), (gen2, gen3, gen4)) ->
              (gen0, gen1, gen2, gen3, gen4))
            (QCheck.Gen.pair
               (QCheck.Gen.pair QCheck.Gen.int QCheck.Gen.int)
               (QCheck.Gen.triple QCheck.Gen.int QCheck.Gen.int QCheck.Gen.int))];
      [%stri
        let gen =
          QCheck.Gen.map
            (fun ((gen0, gen1, gen2), (gen3, gen4, gen5)) ->
              (gen0, gen1, gen2, gen3, gen4, gen5))
            (QCheck.Gen.pair
               (QCheck.Gen.triple QCheck.Gen.int QCheck.Gen.int QCheck.Gen.int)
               (QCheck.Gen.triple QCheck.Gen.int QCheck.Gen.int QCheck.Gen.int))];
    ]
  in

  check_eq ~expected ~actual "deriving tuples"

let test_option () =
  let expected = [ [%stri let gen = QCheck.Gen.option QCheck.Gen.int] ] in
  let actual = f' @@ extract' [ [%stri type t = int option] ] in
  check_eq ~expected ~actual "deriving option"

let test_array () =
  let expected = [ [%stri let gen = QCheck.Gen.array QCheck.Gen.int] ] in
  let actual = f' @@ extract' [ [%stri type t = int array] ] in
  check_eq ~expected ~actual "deriving option"

let test_list () =
  let expected = [ [%stri let gen = QCheck.Gen.list QCheck.Gen.string] ] in

  let actual = f' @@ extract' [ [%stri type t = string list] ] in
  check_eq ~expected ~actual "deriving list"

let test_alpha () =
  let expected =
    [
      [%stri let gen gen_a = gen_a];
      [%stri let gen gen_a = QCheck.Gen.list gen_a];
      [%stri let gen gen_a = QCheck.Gen.map (fun gen0 -> A gen0) gen_a];
      [%stri
        let gen gen_a gen_b =
          QCheck.Gen.map
            (fun (gen0, gen1) -> A (gen0, gen1))
            (QCheck.Gen.pair gen_a gen_b)];
      [%stri
        let gen gen_left gen_right =
          QCheck.Gen.map
            (fun (gen0, gen1) -> (gen0, gen1))
            (QCheck.Gen.pair gen_left gen_right)];
      [%stri
        let gen_tree gen_a =
          QCheck.Gen.sized
          @@ QCheck.Gen.fix (fun self -> function
               | 0 -> QCheck.Gen.map (fun gen0 -> Leaf gen0) gen_a
               | n ->
                   QCheck.Gen.frequency
                     [
                       (1, QCheck.Gen.map (fun gen0 -> Leaf gen0) gen_a);
                       ( 1,
                         QCheck.Gen.map
                           (fun (gen0, gen1) -> Node (gen0, gen1))
                           (QCheck.Gen.pair (self (n / 2)) (self (n / 2))) );
                     ])];
    ]
  in
  let actual =
    f'
    @@ extract'
         [
           [%stri type 'a t = 'a];
           [%stri type 'a t = 'a list];
           [%stri type 'a t = A of 'a];
           [%stri type ('a, 'b) t = A of 'a * 'b];
           [%stri type ('left, 'right) t = 'left * 'right];
           [%stri type 'a tree = Leaf of 'a | Node of 'a tree * 'a tree];
         ]
  in
  check_eq ~expected ~actual "deriving alpha"

let test_equal () =
  let expected =
    [
      [%stri
        let gen =
          QCheck.Gen.frequency
            [
              (1, QCheck.Gen.pure A);
              (1, QCheck.Gen.pure B);
              (1, QCheck.Gen.pure C);
            ]];
      [%stri
        let gen_t' =
          QCheck.Gen.frequency
            [
              (1, QCheck.Gen.pure A);
              (1, QCheck.Gen.pure B);
              (1, QCheck.Gen.pure C);
            ]];
    ]
  in
  let actual =
    f'
    @@ extract'
         [ [%stri type t = A | B | C]; [%stri type t' = t = A | B | C] ]
  in
  check_eq ~expected ~actual "deriving equal"

let test_dependencies () =
  let expected =
    [
      [%stri
        let gen =
          QCheck.Gen.frequency
            [
              (1, QCheck.Gen.map (fun gen0 -> Int gen0) SomeModule.gen);
              ( 1,
                QCheck.Gen.map
                  (fun gen0 -> Float gen0)
                  SomeModule.SomeOtherModule.gen );
            ]];
      [%stri let gen = gen_something];
    ]
  in
  let actual =
    f'
    @@ extract'
         [
           [%stri
             type t =
               | Int of SomeModule.t
               | Float of SomeModule.SomeOtherModule.t];
           [%stri type t = (Something.t[@gen gen_something])];
         ]
  in

  check_eq ~expected ~actual "deriving dependencies"

let test_konstr () =
  let expected =
    [
      [%stri let gen = QCheck.Gen.map (fun gen0 -> A gen0) QCheck.Gen.int];
      [%stri
        let gen =
          QCheck.Gen.frequency
            [
              (1, QCheck.Gen.map (fun gen0 -> B gen0) QCheck.Gen.int);
              (1, QCheck.Gen.map (fun gen0 -> C gen0) QCheck.Gen.int);
            ]];
      [%stri
        let gen =
          QCheck.Gen.frequency
            [
              (1, QCheck.Gen.map (fun gen0 -> X gen0) gen_t1);
              (1, QCheck.Gen.map (fun gen0 -> Y gen0) gen_t2);
              (1, QCheck.Gen.map (fun gen0 -> Z gen0) QCheck.Gen.string);
            ]];
      [%stri
        let gen =
          QCheck.Gen.frequency
            [ (1, QCheck.Gen.pure Left); (1, QCheck.Gen.pure Right) ]];
      [%stri
        let gen =
          QCheck.Gen.frequency
            [
              (1, QCheck.Gen.map (fun gen0 -> Simple gen0) QCheck.Gen.int);
              ( 1,
                QCheck.Gen.map
                  (fun (gen0, gen1) -> Double (gen0, gen1))
                  (QCheck.Gen.pair QCheck.Gen.int QCheck.Gen.int) );
              ( 1,
                QCheck.Gen.map
                  (fun (gen0, gen1, gen2) -> Triple (gen0, gen1, gen2))
                  (QCheck.Gen.triple
                     QCheck.Gen.int
                     QCheck.Gen.int
                     QCheck.Gen.int) );
            ]];
    ]
  in
  let actual =
    f'
    @@ extract'
         [
           [%stri type t = A of int];
           [%stri type t = B of int | C of int];
           [%stri type t = X of t1 | Y of t2 | Z of string];
           [%stri type t = Left | Right];
           [%stri
             type t =
               | Simple of int
               | Double of int * int
               | Triple of int * int * int];
         ]
  in
  check_eq ~expected ~actual "deriving constructors"

let test_record () =
  let expected =
    [
      [%stri
        let gen =
          QCheck.Gen.map
            (fun (gen0, gen1) -> { a = gen0; b = gen1 })
            (QCheck.Gen.pair QCheck.Gen.int QCheck.Gen.string)];
      [%stri
        let gen =
          QCheck.Gen.map
            (fun (gen0, gen1) -> { a = gen0; b = gen1 })
            (QCheck.Gen.pair QCheck.Gen.int QCheck.Gen.string)];
      [%stri
        let gen =
          QCheck.Gen.frequency
            [
              (1, QCheck.Gen.map (fun gen0 -> A gen0) gen_t');
              ( 1,
                QCheck.Gen.map
                  (fun (gen0, gen1) -> B { left = gen0; right = gen1 })
                  (QCheck.Gen.pair QCheck.Gen.int QCheck.Gen.int) );
            ]];
    ]
  in
  let actual =
    f'
    @@ extract'
         [
           [%stri type t = { a : int; b : string }];
           [%stri type t = { mutable a : int; mutable b : string }];
           [%stri type t = A of t' | B of { left : int; right : int }];
         ]
  in
  check_eq ~expected ~actual "deriving record"

let test_variant () =
  let expected =
    [
      [%stri
        let gen =
          (QCheck.Gen.frequency
             [
               (1, QCheck.Gen.pure `A);
               (1, QCheck.Gen.map (fun gen0 -> `B gen0) QCheck.Gen.int);
               (1, QCheck.Gen.map (fun gen0 -> `C gen0) QCheck.Gen.string);
             ]
            : t QCheck.Gen.t)];
      [%stri
        let gen =
          (QCheck.Gen.sized
           @@ QCheck.Gen.fix (fun self -> function
                | 0 ->
                    QCheck.Gen.frequency
                      [
                        (1, QCheck.Gen.pure `A);
                        (1, QCheck.Gen.map (fun gen0 -> `B gen0) QCheck.Gen.int);
                        ( 1,
                          QCheck.Gen.map (fun gen0 -> `C gen0) QCheck.Gen.string
                        );
                      ]
                | n ->
                    QCheck.Gen.frequency
                      [
                        (1, QCheck.Gen.pure `A);
                        (1, QCheck.Gen.map (fun gen0 -> `B gen0) QCheck.Gen.int);
                        ( 1,
                          QCheck.Gen.map (fun gen0 -> `C gen0) QCheck.Gen.string
                        );
                        (1, QCheck.Gen.map (fun gen0 -> `D gen0) (self (n / 2)));
                      ])
            : t QCheck.Gen.t)];
      [%stri
        let gen_t' =
          (QCheck.Gen.frequency [ (1, QCheck.Gen.pure `B); (1, gen) ]
            : t' QCheck.Gen.t)];
    ]
  in
  let actual =
    f'
    @@ extract'
         [
           [%stri type t = [ `A | `B of int | `C of string ]];
           [%stri type t = [ `A | `B of int | `C of string | `D of t ]];
           [%stri type t' = [ `B | t ]];
         ]
  in
  check_eq ~expected ~actual "deriving variant"

let test_tree () =
  let expected =
    [
      [%stri
        let gen_tree =
          QCheck.Gen.sized
          @@ QCheck.Gen.fix (fun self -> function
               | 0 -> QCheck.Gen.pure Leaf
               | n ->
                   QCheck.Gen.frequency
                     [
                       (1, QCheck.Gen.pure Leaf);
                       ( 1,
                         QCheck.Gen.map
                           (fun (gen0, gen1, gen2) -> Node (gen0, gen1, gen2))
                           (QCheck.Gen.triple
                              QCheck.Gen.int
                              (self (n / 2))
                              (self (n / 2))) );
                     ])];
      [%stri
        let gen_expr =
          QCheck.Gen.sized
          @@ QCheck.Gen.fix (fun self -> function
               | 0 -> QCheck.Gen.map (fun gen0 -> Value gen0) QCheck.Gen.int
               | n ->
                   QCheck.Gen.frequency
                     [
                       ( 1,
                         QCheck.Gen.map (fun gen0 -> Value gen0) QCheck.Gen.int
                       );
                       ( 1,
                         QCheck.Gen.map
                           (fun (gen0, gen1, gen2) -> If (gen0, gen1, gen2))
                           (QCheck.Gen.triple
                              (self (n / 2))
                              (self (n / 2))
                              (self (n / 2))) );
                       ( 1,
                         QCheck.Gen.map
                           (fun (gen0, gen1) -> Eq (gen0, gen1))
                           (QCheck.Gen.pair (self (n / 2)) (self (n / 2))) );
                       ( 1,
                         QCheck.Gen.map
                           (fun (gen0, gen1) -> Lt (gen0, gen1))
                           (QCheck.Gen.pair (self (n / 2)) (self (n / 2))) );
                     ])];
    ]
  in
  let actual =
    f'
    @@ extract'
         [
           [%stri type tree = Leaf | Node of int * tree * tree];
           [%stri
             type expr =
               | Value of int
               | If of expr * expr * expr
               | Eq of expr * expr
               | Lt of expr * expr];
         ]
  in
  check_eq ~expected ~actual "deriving tree"

let test_recursive () =
  let expected =
    [
      [%stri
        let rec gen_expr () =
          QCheck.Gen.sized
          @@ QCheck.Gen.fix (fun self -> function
               | 0 -> QCheck.Gen.map (fun gen0 -> Value gen0) (gen_value ())
               | n ->
                   QCheck.Gen.frequency
                     [
                       ( 1,
                         QCheck.Gen.map (fun gen0 -> Value gen0) (gen_value ())
                       );
                       ( 1,
                         QCheck.Gen.map
                           (fun (gen0, gen1, gen2) -> If (gen0, gen1, gen2))
                           (QCheck.Gen.triple
                              (self (n / 2))
                              (self (n / 2))
                              (self (n / 2))) );
                       ( 1,
                         QCheck.Gen.map
                           (fun (gen0, gen1) -> Eq (gen0, gen1))
                           (QCheck.Gen.pair (self (n / 2)) (self (n / 2))) );
                       ( 1,
                         QCheck.Gen.map
                           (fun (gen0, gen1) -> Lt (gen0, gen1))
                           (QCheck.Gen.pair (self (n / 2)) (self (n / 2))) );
                     ])

        and gen_value () =
          QCheck.Gen.frequency
            [
              (1, QCheck.Gen.map (fun gen0 -> Bool gen0) QCheck.Gen.bool);
              (1, QCheck.Gen.map (fun gen0 -> Int gen0) QCheck.Gen.int);
            ]];
      [%stri let gen_expr = gen_expr ()];
      [%stri let gen_value = gen_value ()];
    ]
  in

  let actual =
    f
    @@ extract
         [%stri
           type expr =
             | Value of value
             | If of expr * expr * expr
             | Eq of expr * expr
             | Lt of expr * expr

           and value = Bool of bool | Int of int]
  in
  check_eq ~expected ~actual "deriving recursive"

let test_forest () =
  let expected =
    [
      [%stri
        let rec gen_tree () =
          QCheck.Gen.map
            (fun gen0 -> Node gen0)
            (QCheck.Gen.map
               (fun (gen0, gen1) -> (gen0, gen1))
               (QCheck.Gen.pair QCheck.Gen.int (gen_forest ())))

        and gen_forest () =
          QCheck.Gen.sized
          @@ QCheck.Gen.fix (fun self -> function
               | 0 -> QCheck.Gen.pure Nil
               | n ->
                   QCheck.Gen.frequency
                     [
                       (1, QCheck.Gen.pure Nil);
                       ( 1,
                         QCheck.Gen.map
                           (fun gen0 -> Cons gen0)
                           (QCheck.Gen.map
                              (fun (gen0, gen1) -> (gen0, gen1))
                              (QCheck.Gen.pair (gen_tree ()) (self (n / 2)))) );
                     ])];
      [%stri let gen_tree = gen_tree ()];
      [%stri let gen_forest = gen_forest ()];
    ]
  in
  let actual =
    f
    @@ extract
         [%stri
           type tree = Node of (int * forest)

           and forest = Nil | Cons of (tree * forest)]
  in
  check_eq ~expected ~actual "deriving forest"

let test_fun_primitives () =
  let expected =
    [
      [%stri
        let gen =
          QCheck.fun_nary
            QCheck.Tuple.(
              QCheck.Observable.int @-> QCheck.Observable.int @-> o_nil)
            (QCheck.make QCheck.Gen.string)
          |> QCheck.gen];
      [%stri
        let gen =
          QCheck.fun_nary
            QCheck.Tuple.(
              QCheck.Observable.float @-> QCheck.Observable.float @-> o_nil)
            (QCheck.make QCheck.Gen.string)
          |> QCheck.gen];
      [%stri
        let gen =
          QCheck.fun_nary
            QCheck.Tuple.(
              QCheck.Observable.string @-> QCheck.Observable.string @-> o_nil)
            (QCheck.make QCheck.Gen.string)
          |> QCheck.gen];
      [%stri
        let gen =
          QCheck.fun_nary
            QCheck.Tuple.(
              QCheck.Observable.bool @-> QCheck.Observable.bool @-> o_nil)
            (QCheck.make QCheck.Gen.string)
          |> QCheck.gen];
      [%stri
        let gen =
          QCheck.fun_nary
            QCheck.Tuple.(
              QCheck.Observable.char @-> QCheck.Observable.char @-> o_nil)
            (QCheck.make QCheck.Gen.string)
          |> QCheck.gen];
      [%stri
        let gen =
          QCheck.fun_nary
            QCheck.Tuple.(QCheck.Observable.unit @-> o_nil)
            (QCheck.make QCheck.Gen.string)
          |> QCheck.gen];
    ]
  in

  let actual =
    f'
    @@ extract'
         [
           [%stri type t = int -> int -> string];
           [%stri type t = float -> float -> string];
           [%stri type t = string -> string -> string];
           [%stri type t = bool -> bool -> string];
           [%stri type t = char -> char -> string];
           [%stri type t = unit -> string];
         ]
  in
  check_eq ~expected ~actual "deriving fun primitives"

let test_fun_n () =
  let expected =
    [
      [%stri
        let gen =
          QCheck.fun_nary
            QCheck.Tuple.(
              QCheck.Observable.bool @-> QCheck.Observable.int
              @-> QCheck.Observable.float @-> QCheck.Observable.string
              @-> QCheck.Observable.char @-> o_nil)
            (QCheck.make QCheck.Gen.unit)
          |> QCheck.gen];
    ]
  in
  let actual =
    f @@ extract [%stri type t = bool -> int -> float -> string -> char -> unit]
  in
  check_eq ~expected ~actual "deriving fun n"

let test_fun_option () =
  let expected =
    [
      [%stri
        let gen =
          QCheck.fun_nary
            QCheck.Tuple.(
              QCheck.Observable.option QCheck.Observable.int @-> o_nil)
            (QCheck.make QCheck.Gen.unit)
          |> QCheck.gen];
    ]
  in
  let actual = f @@ extract [%stri type t = int option -> unit] in
  check_eq ~expected ~actual "deriving fun option"

let test_fun_list () =
  let expected =
    [
      [%stri
        let gen =
          QCheck.fun_nary
            QCheck.Tuple.(
              QCheck.Observable.list QCheck.Observable.int @-> o_nil)
            (QCheck.make QCheck.Gen.unit)
          |> QCheck.gen];
    ]
  in
  let actual = f @@ extract [%stri type t = int list -> unit] in
  check_eq ~expected ~actual "deriving fun list"

let test_fun_array () =
  let expected =
    [
      [%stri
        let gen =
          QCheck.fun_nary
            QCheck.Tuple.(
              QCheck.Observable.array QCheck.Observable.int @-> o_nil)
            (QCheck.make QCheck.Gen.unit)
          |> QCheck.gen];
    ]
  in
  let actual = f @@ extract [%stri type t = int array -> unit] in
  check_eq ~expected ~actual "deriving fun array"

let test_fun_tuple () =
  let expected =
    [
      [%stri
        let gen =
          QCheck.fun_nary
            QCheck.Tuple.(
              QCheck.Observable.pair QCheck.Observable.int QCheck.Observable.int
              @-> o_nil)
            (QCheck.make QCheck.Gen.unit)
          |> QCheck.gen];
      [%stri
        let gen =
          QCheck.fun_nary
            QCheck.Tuple.(
              QCheck.Observable.triple
                QCheck.Observable.int
                QCheck.Observable.int
                QCheck.Observable.int
              @-> o_nil)
            (QCheck.make QCheck.Gen.unit)
          |> QCheck.gen];
      [%stri
        let gen =
          QCheck.fun_nary
            QCheck.Tuple.(
              QCheck.Observable.quad
                QCheck.Observable.int
                QCheck.Observable.int
                QCheck.Observable.int
                QCheck.Observable.int
              @-> o_nil)
            (QCheck.make QCheck.Gen.unit)
          |> QCheck.gen];
    ]
  in
  let actual =
    f'
    @@ extract'
         [
           [%stri type t = int * int -> unit];
           [%stri type t = int * int * int -> unit];
           [%stri type t = int * int * int * int -> unit];
         ]
  in
  check_eq ~expected ~actual "deriving fun tuple"

let test_weight_konstrs () =
  let expected =
    [
      [%stri
        let gen =
          QCheck.Gen.frequency
            [
              (5, QCheck.Gen.pure A);
              (6, QCheck.Gen.pure B);
              (1, QCheck.Gen.pure C);
            ]];
    ]
  in
  let actual =
    f @@ extract [%stri type t = A [@weight 5] | B [@weight 6] | C]
  in
  check_eq ~expected ~actual "deriving weight konstrs"

(* Regression test: https://github.com/c-cube/qcheck/issues/187 *)
let test_recursive_poly_variant () =
  let expected =
    [
      [%stri
        let gen_tree =
          (QCheck.Gen.sized
           @@ QCheck.Gen.fix (fun self -> function
                | 0 -> QCheck.Gen.map (fun gen0 -> `Leaf gen0) QCheck.Gen.int
                | n ->
                    QCheck.Gen.frequency
                      [
                        ( 1,
                          QCheck.Gen.map (fun gen0 -> `Leaf gen0) QCheck.Gen.int
                        );
                        ( 1,
                          QCheck.Gen.map
                            (fun gen0 -> `Node gen0)
                            (QCheck.Gen.map
                               (fun (gen0, gen1) -> (gen0, gen1))
                               (QCheck.Gen.pair (self (n / 2)) (self (n / 2))))
                        );
                      ])
            : tree QCheck.Gen.t)];
    ]
  in
  let actual =
    f @@ extract [%stri type tree = [ `Leaf of int | `Node of tree * tree ]]
  in
  check_eq ~expected ~actual "deriving recursive polymorphic variants"

let () =
  Alcotest.(
    run
      "ppx_deriving_qcheck tests"
      [
        ( "deriving generator good",
          [
            test_case "deriving int" `Quick test_int;
            test_case "deriving float" `Quick test_float;
            test_case "deriving char" `Quick test_char;
            test_case "deriving string" `Quick test_string;
            test_case "deriving unit" `Quick test_unit;
            test_case "deriving bool" `Quick test_bool;
            test_case "deriving int32" `Quick test_int32;
            test_case "deriving int32'" `Quick test_int32';
            test_case "deriving int64" `Quick test_int64;
            test_case "deriving int64'" `Quick test_int64';
            (* test_case "deriving bytes" `Quick test_bytes; *)
            test_case "deriving tuple" `Quick test_tuple;
            test_case "deriving option" `Quick test_option;
            test_case "deriving array" `Quick test_array;
            test_case "deriving list" `Quick test_list;
            test_case "deriving constructors" `Quick test_konstr;
            test_case "deriving dependencies" `Quick test_dependencies;
            test_case "deriving record" `Quick test_record;
            test_case "deriving equal" `Quick test_equal;
            test_case "deriving tree like" `Quick test_tree;
            test_case "deriving alpha" `Quick test_alpha;
            test_case "deriving variant" `Quick test_variant;
            test_case "deriving weight constructors" `Quick test_weight_konstrs;
            test_case "deriving recursive" `Quick test_recursive;
            test_case "deriving forest" `Quick test_forest;
            test_case "deriving fun primitives" `Quick test_fun_primitives;
            test_case "deriving fun option" `Quick test_fun_option;
            test_case "deriving fun array" `Quick test_fun_array;
            test_case "deriving fun list" `Quick test_fun_list;
            test_case "deriving fun n" `Quick test_fun_n;
            test_case "deriving fun tuple" `Quick test_fun_tuple;
            test_case
              "deriving rec poly variants"
              `Quick
              test_recursive_poly_variant;
          ] );
      ])
