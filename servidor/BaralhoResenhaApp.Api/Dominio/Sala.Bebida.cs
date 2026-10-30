namespace BaralhoResenhaApp.Api.Dominio;

/// <summary>O que a carta da mesa fez com alguém: pontos no cofrinho e goles de dose.</summary>
public sealed class ContaDaCarta
{
    public int Pontos { get; set; }
    public int Goles { get; set; }

    /// <summary>Dose de quem joga sem álcool vira ponto: não bebe agora.</summary>
    public bool SemAlcool { get; set; }

    public bool Vazia => Pontos == 0 && Goles == 0;
}

/// <summary>
/// Cofrinho de goles: cada vez que a carta pega alguém vale um ponto, e o
/// gole de verdade só sai quando o cofrinho enche. Com gole a cada carta, a
/// turma fica bêbada em meia hora. A carta que diz "bebe 2" é dose: gole de
/// verdade, fora do cofrinho. Tudo fica anotado na conta da carta, que as
/// cartas na manga mexem.
/// </summary>
public sealed partial class Sala
{
    private ContaDaCarta Conta(Jogador jogador)
    {
        var contas = Rodada!.Contas;
        if (!contas.TryGetValue(jogador.Id, out var conta))
            contas[jogador.Id] = conta = new ContaDaCarta { SemAlcool = SoPontos(jogador) };
        return conta;
    }

    private void Pegar(Jogador jogador)
    {
        jogador.Pontos++;
        Conta(jogador).Pontos++;
        // Quem joga sem álcool só junta pontos.
        if (SoPontos(jogador)) return;
        jogador.Cofrinho++;
        if (jogador.Cofrinho < Configuracao.PontosPorGole) return;
        jogador.Cofrinho = 0;
        jogador.Goles++;
        Rodada!.EncheuCofrinho.Add(jogador.Id);
    }

    /// <summary>Desfaz um <see cref="Pegar"/> da carta atual (desmarcou o "Me pegou").</summary>
    private void Despegar(Jogador jogador)
    {
        var conta = Conta(jogador);
        // Já foi embora com uma carta na manga: não há o que desfazer.
        if (conta.Pontos == 0) return;
        conta.Pontos--;
        jogador.Pontos = Math.Max(0, jogador.Pontos - 1);
        if (SoPontos(jogador)) return;
        if (Rodada!.EncheuCofrinho.Remove(jogador.Id))
        {
            jogador.Goles--;
            jogador.Cofrinho = Configuracao.PontosPorGole - 1;
        }
        else if (jogador.Cofrinho > 0)
        {
            jogador.Cofrinho--;
        }
    }

    /// <summary>Gole de verdade, fora do cofrinho (para quem joga sem álcool, pontos).</summary>
    private void Dose(Jogador jogador, int goles)
    {
        Conta(jogador).Goles += goles;
        jogador.Pontos += goles;
        if (!SoPontos(jogador)) jogador.Goles += goles;
    }

    private void TirarDose(Jogador jogador, int goles)
    {
        var conta = Conta(jogador);
        goles = Math.Min(goles, conta.Goles);
        if (goles <= 0) return;
        conta.Goles -= goles;
        jogador.Pontos = Math.Max(0, jogador.Pontos - goles);
        if (!SoPontos(jogador)) jogador.Goles -= goles;
    }

    /// <summary>
    /// O que a carta faz com quem ela pegou: na carta comum, ponto no cofrinho;
    /// na que diz "bebe 2", gole de verdade, fora do cofrinho.
    /// </summary>
    private void Punir(Jogador jogador)
    {
        if (Rodada!.Carta.Goles is { } goles) Dose(jogador, goles);
        else Pegar(jogador);
    }

    /// <summary>Desfaz um <see cref="Punir"/> da carta atual.</summary>
    private void Perdoar(Jogador jogador)
    {
        if (Rodada!.Carta.Goles is { } goles) TirarDose(jogador, goles);
        else Despegar(jogador);
    }
}
