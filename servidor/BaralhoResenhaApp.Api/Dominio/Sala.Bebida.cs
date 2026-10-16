namespace BaralhoResenhaApp.Api.Dominio;

/// <summary>
/// Cofrinho de goles: cada vez que a carta pega alguém vale um ponto, e o
/// gole de verdade só sai quando o cofrinho enche. Com gole a cada carta, a
/// turma fica bêbada em meia hora.
/// </summary>
public sealed partial class Sala
{
    private void Pegar(Jogador jogador)
    {
        jogador.Pontos++;
        // Quem joga sem álcool só junta pontos.
        if (jogador.SemAlcool) return;
        jogador.Cofrinho++;
        if (jogador.Cofrinho < Configuracao.PontosPorGole) return;
        jogador.Cofrinho = 0;
        jogador.Goles++;
        Rodada!.BebemAgora.Add(jogador.Id);
    }

    /// <summary>Desfaz um <see cref="Pegar"/> da carta atual (desmarcou o "Me pegou").</summary>
    private void Despegar(Jogador jogador)
    {
        if (jogador.Pontos == 0) return;
        jogador.Pontos--;
        if (jogador.SemAlcool) return;
        if (Rodada!.BebemAgora.Remove(jogador.Id))
        {
            jogador.Goles--;
            jogador.Cofrinho = Configuracao.PontosPorGole - 1;
        }
        else if (jogador.Cofrinho > 0)
        {
            jogador.Cofrinho--;
        }
    }
}
