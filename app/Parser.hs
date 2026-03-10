module Parser (
  formula,
) where

import Data.Void (Void)
import Text.Megaparsec
import Text.Megaparsec.Char
import Text.Megaparsec.Char.Lexer qualified as L

import CNF hiding (identifier)

type Parser = Parsec Void String

lexeme :: Parser a -> Parser a
lexeme = L.lexeme space

symbol :: String -> Parser String
symbol = L.symbol space

-- An identifier consists of letters.
identifier :: Parser String
identifier = label "identifier" $ lexeme (some letterChar)

-- literal := posLiteral | negLiteral
literal :: Parser (CNF Literal)
literal = label "literal" $ negLiteral <|> posLiteral
 where
  posLiteral = Pos <$> identifier
  negLiteral = Neg <$> (symbol "¬" *> identifier)

-- disjunction := literal | `(` literal ( `∨` literal )+ `)`
disjunction :: Parser (CNF Disjunction)
disjunction = label "disjunction" $ Or <$> (try oneLiteral <|> moreLiterals)
 where
  oneLiteral = pure <$> literal
  moreLiterals = between (symbol "(") (symbol ")") $ sepBy1 literal (symbol "∨")

-- conjunction := disjunction ( `∧` disjunction )*
conjunction :: Parser (CNF Conjunction)
conjunction = label "conjunction" $ And <$> sepBy1 disjunction (symbol "∧")

-- formula := conjunction
formula :: Parser (CNF Conjunction)
formula = label "formula" $ space *> conjunction <* eof
