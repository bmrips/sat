{-# LANGUAGE LambdaCase #-}

module Options (
  Options (..),
  OutputFormat (..),
  optionsInfo,
) where

import Options.Applicative
import Text.Megaparsec (parseMaybe)

import CNF
import Parser qualified

-- The options.
data Options = Options
  { formula :: CNF Conjunction
  , listSteps :: Bool
  , outputFormat :: OutputFormat
  , showSolution :: Bool
  }

-- The output format.
data OutputFormat = Text | Latex

-- The option parser.
options :: Parser Options
options =
  Options
    <$> formula
    <*> listSteps
    <*> outputFormat
    <*> showSolution
 where
  formula = argument parseFormula (metavar "FORMULA")
   where
    parseFormula = eitherReader $
      \s -> case parseMaybe Parser.formula s of
        Nothing -> Left "parse error."
        Just f -> Right f
  listSteps =
    switch $
      long "list-steps"
        <> short 'l'
        <> help "List the steps of the DPLL algorithm execution."
  outputFormat =
    option parseOutputFormat $
      long "output-format"
        <> short 'o'
        <> metavar "FORMAT"
        <> value Text
        <> showDefaultWith showOutputFormat
        <> help "The output format. Currently supported: text and latex. Defaults to text."
   where
    parseOutputFormat = eitherReader $ \case
      "text" -> Right Text
      "latex" -> Right Latex
      fmt -> Left $ "unknown output format: " ++ fmt ++ "."
    showOutputFormat = \case
      Text -> "text"
      Latex -> "latex"
  showSolution =
    switch $
      long "show-solution"
        <> short 's'
        <> help "Show a solution to the formula, if satisfiable."

-- The option parser with the global program info and description.
optionsInfo :: ParserInfo Options
optionsInfo =
  info (helper <*> options) $
    fullDesc
      <> progDesc "Determine the satisfiability of Boolean formulae."
      <> header "sat — a SAT solver"
