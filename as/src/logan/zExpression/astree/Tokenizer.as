/**
 * User: logan
 * Date: 11/19/12
 * Time: 1:22 PM
 * Email: xorcererzc@gmail.com
 */
package logan.zExpression.astree
{
	import logan.zExpression.*;
	import logan.zExpression.errors.InvalidExpressionError;
	import logan.zExpression.errors.UnexpectedCharError;

	public class Tokenizer
	{
		public static function tokenize(expressionStr:String, letterValidator:Function = null):Array
		{
			letterValidator ||= Utils.isLetter

			var tokens:Array = []
			var tokenizer:Tokenizer = new Tokenizer(letterValidator);
			for (var i:int = 0; i < expressionStr.length; ++i)
			{
				try
				{
					var token:String = tokenizer.inputChar(expressionStr.charAt(i))
					if (token != null)
						tokens.push(token)
				}
				catch(e:InvalidExpressionError)
				{
					e.setExpressionAndErrorPosition(expressionStr, i)
					throw e
				}
			}
			tokens.push(tokenizer.popLastToken())

			return tokens
		}

		private var _letterValidator:Function

		public function Tokenizer(letterValidator:Function = null)
		{
			_letterValidator = letterValidator || Utils.isLetter
		}

		private var validExpression:Boolean = true

		private var _untokenizedLetters:Array = []

		public function get finished():Boolean
		{
			return !validExpression || _untokenizedLetters == null
		}

		private var _currentTokenType:uint = Token.TYPE_NONE
		private var _dotOfNumberAppeared:Boolean = false

		/*
		 * Input chars one by one, return a not-null string if a token constructed.
		 */
		private function inputChar(currentChar:String):String
		{
			if (finished) return null

			isCharOrThrow(currentChar)

			switch (currentChar)
			{
				case '+':
				case '-':
				case '*':
				case '/':
				case ',':
					_currentTokenType = Token.TYPE_OPERATOR
					return getThenResetLastToken(currentChar)
				case '(':
					_currentTokenType = Token.TYPE_OPEN_PARENTHESIS
					return getThenResetLastToken(currentChar)
				case ')':
					_currentTokenType = Token.TYPE_CLOSE_PARENTHESIS
					return getThenResetLastToken(currentChar)
				case ' ':
					// Simply skip it.
					return null
			}

			if (_letterValidator(currentChar) || currentChar == "_")
			{
				if (_currentTokenType == Token.TYPE_VAR)
				{
					_untokenizedLetters.push(currentChar)
				}
				else
				{
					_currentTokenType = Token.TYPE_VAR
					return getThenResetLastToken(currentChar)
				}
			}

			else if (Utils.isDigit(currentChar))
			{
				if (_currentTokenType == Token.TYPE_VAR || _currentTokenType == Token.TYPE_NUMBER)
				{
					_untokenizedLetters.push(currentChar)
				}
				else
				{
					_currentTokenType = Token.TYPE_NUMBER
					_dotOfNumberAppeared = false
					return getThenResetLastToken(currentChar)
				}
			}

			else if (currentChar == '.')
			{
				if (_dotOfNumberAppeared)
				{
					validExpression = false
					throw new UnexpectedCharError(currentChar)
				}

				if (_currentTokenType == Token.TYPE_NUMBER)
				{
					_dotOfNumberAppeared = true
					_untokenizedLetters.push(currentChar)
				}
			}
			else
			{
				throw new UnexpectedCharError(currentChar)
			}

			return null;
		}

		public function popLastToken():String
		{
			if (finished || _untokenizedLetters.length == 0) return null

			var lastToken:String = _untokenizedLetters.join('')
			_untokenizedLetters = null
			return lastToken
		}

		private function getThenResetLastToken(newChar:String):String
		{
			isCharOrThrow(newChar)

			var lastToken:String = _untokenizedLetters.join('')
			if  (isSpace(newChar))
				_untokenizedLetters = []
			else
				_untokenizedLetters = [newChar]
			return (lastToken.length > 0 ? lastToken : null)
		}

		private function isSpace(char:String):Boolean
		{
			isCharOrThrow(char)
			return char == ' '
		}

		private function isCharOrThrow(c:String):void
		{
			if (c == null || c.length > 1)
				throw ArgumentError("currentChar should be a single character string.")
		}
	}
}