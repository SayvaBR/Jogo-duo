"""One-time repairs for the first Dart port, before flutter test/build.

This script is intentionally strict: each change must match exactly once. Once the
normalized files have been committed, rerunning it is a no-op.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / 'lib'


def fix(name: str, before: str, after: str) -> None:
    file = ROOT / name
    original = file.read_text(encoding='utf-8')
    count = original.count(before)
    if count == 0:
        if after not in original:
            raise RuntimeError(f'{name}: expected source fragment missing: {before!r}')
        return
    if count != 1:
        raise RuntimeError(f'{name}: expected one source fragment, found {count}: {before!r}')
    file.write_text(original.replace(before, after, 1), encoding='utf-8')
    print(f'Repaired {name}: {before[:48]}')


fix('board_games.dart', 'color:cells[i]==1?blue:pink))))))),', 'color:cells[i]==1?blue:pink)))))))),')
# The Connect Four grid was missing the closing parentheses of AspectRatio/ConstrainedBox.
original_four = 'width:2))))))])))))),'
fix('board_games.dart', original_four, original_four[:-1] + ')),')
fix('ludo.dart', 'color:count==n?ink:Colors.white))))]),', 'color:count==n?ink:Colors.white)))))]) ,'.replace(']) ,', ']),'))
# Arrow-expression build methods must end with a semicolon, not a method-body brace.
fix('arcade_games.dart', ' ]))));}\n}\nclass _Hockey', ' ]))));\n}\nclass _Hockey')
fix('arcade_games.dart', ' ]))));}\n}\nclass _Pool', ' ]))));\n}\nclass _Pool')
fix('main.dart', ' ]))));\n }\n}', ' ])));\n }\n}')
# Keep the rendered cue guide aligned with actual shot direction.
fix('arcade_games.dart', 'setState(()=>angle=math.atan2(y-cue.y,x-cue.x));', 'final next=math.atan2(y-cue.y,x-cue.x);engine.setAim(next);setState(()=>angle=next);')
fix('arcade_games.dart', '()=>setState(()=>angle-=math.pi/36)', '()=>setState((){angle-=math.pi/36;engine.setAim(angle);})')
fix('arcade_games.dart', '()=>setState(()=>angle+=math.pi/36)', '()=>setState((){angle+=math.pi/36;engine.setAim(angle);})')
fix('arcade_games.dart', 'int remaining(int player)=>balls.where((b)=>!b.pocketed&&_group(b.id)==groups[player]&&groups[player]!=null).length;', 'int remaining(int player)=>groups[player]==null?7:balls.where((b)=>!b.pocketed&&_group(b.id)==groups[player]).length;')
