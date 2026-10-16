# Guia "Como jogar"

O guia mora em `https://baralho-resenha.onrender.com/como-jogar` e é o link que o dono manda
para a turma. O botão "📖 Como jogar?" da tela inicial abre o mesmo guia.

- Página: `servidor/BaralhoResenhaApp.Api/Paginas/como-jogar/index.html`
- Imagens: `servidor/BaralhoResenhaApp.Api/Paginas/como-jogar/*.jpg`
- Tudo é embutido na DLL e servido por `/como-jogar` e `/como-jogar/{arquivo}` (`Program.cs`).

## Quando atualizar

Toda funcionalidade nova que a turma vê entra no guia, na medida da importância dela:

| Importância | O que fazer no guia |
|---|---|
| Jogo novo, mecânica nova (ex.: cartas na manga, mímica) | Seção ou cartão próprio, com captura da tela |
| Mudança de regra que muda como se joga (ex.: cofrinho, dose) | Atualizar o texto da seção e a captura, se mudou a tela |
| Opção nova de configuração (ex.: noites prontas) | Uma linha em "Configurar a noite" |
| Ajuste visual ou de texto pequeno | Só refazer a captura afetada, se ficou diferente |
| Correção interna, sem efeito na tela | Nada |

Na mesma entrega também entram o "ⓘ Como joga" do app (`cliente/lib/telas/ajuda.dart`) e,
para carta na manga, a ficha (`cartas_na_manga.dart`).

## Refazer as capturas

1. Gere o site e suba um servidor de teste na porta 5091 (o `rodar.ps1` usa a 5090):
   ```powershell
   cd cliente; flutter build web --release; cd ..
   dotnet publish servidor/BaralhoResenhaApp.Api -c Release -o <pasta temporária>
   # copie cliente/build/web para <pasta temporária>/wwwroot e rode:
   <pasta temporária>/BaralhoResenhaApp.Api.exe --urls http://localhost:5091 --contentRoot <pasta temporária>
   ```
2. Em `ferramentas/guia`: `npm install` (uma vez) e
   `node capturar.mjs ../../servidor/BaralhoResenhaApp.Api/Paginas/como-jogar`.
   O roteiro cria salas com selfies de careta e fotografa cada jogo num celular de 390 px.
3. Confira as imagens e o guia em `http://localhost:5091/como-jogar` antes do commit.
